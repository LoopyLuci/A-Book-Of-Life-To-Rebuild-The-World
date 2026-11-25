//! Checking for, downloading and installing updates to the desktop reader.
//!
//! The updater reads the project's GitHub releases. A release carries one
//! Windows package, named `abook-desktop-<tag>-windows-x64.exe`, and a
//! `.sha256` file beside it. A package is accepted only when its SHA-256
//! matches that file.
//!
//! The checksum is published with the package, so it catches a damaged or
//! truncated download but not a release that was itself tampered with. A
//! code-signing certificate would close that gap; none is configured yet.
//!
//! Nothing here draws anything. The interface decides when to call these
//! functions and asks the reader before anything is installed.

use std::fmt;
use std::fs;
use std::io::Read;
use std::path::{Path, PathBuf};
use std::process::Command;
use std::sync::mpsc::{self, Receiver, TryRecvError};
use std::thread;
use std::time::{Duration, Instant};

use sha2::{Digest, Sha256};

/// The repository that publishes the releases.
pub const DEFAULT_REPOSITORY: &str = "LoopyLuci/A-Book-Of-Life-To-Rebuild-The-World";

/// The end of the file name of the Windows package in a release.
pub const PACKAGE_SUFFIX: &str = "windows-x64.exe";

/// The largest package the reader will download.
pub const MAX_PACKAGE_BYTES: u64 = 200 * 1024 * 1024;

/// How long a non-manual mode waits between automatic checks.
pub const CHECK_INTERVAL: Duration = Duration::from_secs(24 * 60 * 60);

/// How the reader handles updates. Manual is the default: nothing is checked
/// or downloaded until the reader asks for it.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum UpdateMode {
    /// Nothing happens until the reader presses "Check now".
    #[default]
    Manual,
    /// Checks and downloads in the background. The reader chooses when to install.
    Download,
    /// Checks, downloads, and then asks the reader before restarting to install.
    DownloadAndInstall,
}

impl UpdateMode {
    /// The name stored in the settings file.
    pub fn id(self) -> &'static str {
        match self {
            Self::Manual => "manual",
            Self::Download => "download",
            Self::DownloadAndInstall => "install",
        }
    }

    /// Reads a stored name. Anything unrecognised falls back to manual.
    pub fn from_id(raw: &str) -> Self {
        match raw.trim() {
            "download" => Self::Download,
            "install" => Self::DownloadAndInstall,
            _ => Self::Manual,
        }
    }
}

/// A version such as `1.2.3` or `1.2.3-alpha`, with or without a leading `v`.
#[derive(Debug, Clone)]
pub struct Version {
    numbers: Vec<u64>,
    pre: Option<String>,
}

impl Version {
    /// Reads a version. Returns `None` when the numbers are not numbers.
    pub fn parse(raw: &str) -> Option<Self> {
        let trimmed = raw.trim().trim_start_matches(['v', 'V']);
        let (core, pre) = match trimmed.split_once('-') {
            Some((core, pre)) if !pre.is_empty() => (core, Some(pre.to_string())),
            Some((core, _)) => (core, None),
            None => (trimmed, None),
        };
        let numbers = core
            .split('.')
            .map(|part| part.parse::<u64>().ok())
            .collect::<Option<Vec<u64>>>()?;
        if numbers.is_empty() {
            return None;
        }
        Some(Self { numbers, pre })
    }
}

impl Ord for Version {
    fn cmp(&self, other: &Self) -> std::cmp::Ordering {
        use std::cmp::Ordering;
        let length = self.numbers.len().max(other.numbers.len());
        for index in 0..length {
            let a = self.numbers.get(index).copied().unwrap_or(0);
            let b = other.numbers.get(index).copied().unwrap_or(0);
            match a.cmp(&b) {
                Ordering::Equal => continue,
                unequal => return unequal,
            }
        }
        // The same numbers with no suffix are newer than with one.
        match (&self.pre, &other.pre) {
            (None, None) => Ordering::Equal,
            (None, Some(_)) => Ordering::Greater,
            (Some(_), None) => Ordering::Less,
            (Some(a), Some(b)) => a.cmp(b),
        }
    }
}

impl PartialOrd for Version {
    fn partial_cmp(&self, other: &Self) -> Option<std::cmp::Ordering> {
        Some(self.cmp(other))
    }
}

impl PartialEq for Version {
    fn eq(&self, other: &Self) -> bool {
        self.cmp(other) == std::cmp::Ordering::Equal
    }
}

impl Eq for Version {}

impl fmt::Display for Version {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        let numbers: Vec<String> = self.numbers.iter().map(u64::to_string).collect();
        write!(f, "{}", numbers.join("."))?;
        if let Some(pre) = &self.pre {
            write!(f, "-{pre}")?;
        }
        Ok(())
    }
}

/// A published release that carries a Windows package.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Release {
    /// The tag, for example `v0.2.0`.
    pub tag: String,
    /// The version the tag names.
    pub version: Version,
    /// The package's file name.
    pub asset_name: String,
    /// Where the package is downloaded from.
    pub asset_url: String,
    /// Where the `.sha256` file for the package is downloaded from.
    pub checksum_url: String,
}

/// Why an update step did not finish. The message is shown to the reader.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum UpdateError {
    /// The network request failed.
    Network(String),
    /// The release data was not what the updater expects.
    Malformed(String),
    /// The release is a draft, which is never offered.
    Draft,
    /// The release has no Windows package.
    NoPackage,
    /// The package does not match its published checksum.
    ChecksumMismatch,
    /// The package is larger than [`MAX_PACKAGE_BYTES`].
    TooLarge,
    /// The program's folder cannot be written without administrator rights.
    /// The downloaded package is kept at this path so the reader can run it.
    NeedsAdministrator(PathBuf),
    /// A file could not be written, read or started.
    Io(String),
}

impl fmt::Display for UpdateError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::Network(detail) => write!(f, "The update server could not be reached: {detail}"),
            Self::Malformed(detail) => write!(f, "The release data was not usable: {detail}"),
            Self::Draft => write!(f, "The newest release is still a draft."),
            Self::NoPackage => write!(f, "The newest release has no Windows package."),
            Self::ChecksumMismatch => {
                write!(f, "The download did not match its checksum and was discarded.")
            }
            Self::TooLarge => write!(f, "The package is larger than the reader accepts."),
            Self::NeedsAdministrator(path) => write!(
                f,
                "The program's folder needs administrator rights. The new version is saved at {}; run it from there to finish.",
                path.display()
            ),
            Self::Io(detail) => write!(f, "A file could not be used: {detail}"),
        }
    }
}

fn io_error(error: std::io::Error) -> UpdateError {
    UpdateError::Io(error.to_string())
}

/// Reads a release from the GitHub releases API response.
pub fn release_from_json(raw: &str) -> Result<Release, UpdateError> {
    let value: serde_json::Value =
        serde_json::from_str(raw).map_err(|error| UpdateError::Malformed(error.to_string()))?;
    if value.get("draft").and_then(serde_json::Value::as_bool) == Some(true) {
        return Err(UpdateError::Draft);
    }
    let tag = value
        .get("tag_name")
        .and_then(serde_json::Value::as_str)
        .ok_or_else(|| UpdateError::Malformed("the release has no tag".to_string()))?
        .to_string();
    let version = Version::parse(&tag)
        .ok_or_else(|| UpdateError::Malformed(format!("the tag {tag} is not a version")))?;

    let assets = value
        .get("assets")
        .and_then(serde_json::Value::as_array)
        .map(Vec::as_slice)
        .unwrap_or(&[]);
    let asset_field = |asset: &serde_json::Value, key: &str| -> Option<String> {
        asset
            .get(key)
            .and_then(serde_json::Value::as_str)
            .map(str::to_string)
    };
    let package = assets
        .iter()
        .find(|asset| {
            asset_field(asset, "name").is_some_and(|name| name.ends_with(PACKAGE_SUFFIX))
        })
        .ok_or(UpdateError::NoPackage)?;
    let asset_name = asset_field(package, "name").ok_or(UpdateError::NoPackage)?;
    let asset_url =
        asset_field(package, "browser_download_url").ok_or(UpdateError::NoPackage)?;

    let checksum_name = format!("{asset_name}.sha256");
    let checksum = assets
        .iter()
        .find(|asset| asset_field(asset, "name").as_deref() == Some(checksum_name.as_str()))
        .ok_or_else(|| UpdateError::Malformed("the package has no checksum file".to_string()))?;
    let checksum_url =
        asset_field(checksum, "browser_download_url").ok_or(UpdateError::NoPackage)?;

    Ok(Release {
        tag,
        version,
        asset_name,
        asset_url,
        checksum_url,
    })
}

/// Reads the SHA-256 for `asset_name` from a `.sha256` file. The file holds
/// `<hex>  <name>`, or just `<hex>`. Returns the digest in lower case.
pub fn parse_checksum(raw: &str, asset_name: &str) -> Option<String> {
    let line = raw.lines().map(str::trim).find(|line| !line.is_empty())?;
    let mut parts = line.split_whitespace();
    let digest = parts.next()?;
    if let Some(name) = parts.next() {
        if name.trim_start_matches('*') != asset_name {
            return None;
        }
    }
    let is_digest = digest.len() == 64 && digest.bytes().all(|byte| byte.is_ascii_hexdigit());
    is_digest.then(|| digest.to_ascii_lowercase())
}

/// The SHA-256 of `bytes`, in lower-case hex.
pub fn sha256_hex(bytes: &[u8]) -> String {
    Sha256::digest(bytes)
        .iter()
        .map(|byte| format!("{byte:02x}"))
        .collect()
}

fn agent() -> ureq::Agent {
    ureq::AgentBuilder::new()
        .timeout_connect(Duration::from_secs(15))
        .timeout_read(Duration::from_secs(20))
        .user_agent(&format!("abook-desktop/{}", env!("CARGO_PKG_VERSION")))
        .build()
}

/// Asks GitHub for the newest published release of `repository`.
pub fn latest_release(repository: &str) -> Result<Release, UpdateError> {
    let url = format!("https://api.github.com/repos/{repository}/releases/latest");
    let body = agent()
        .get(&url)
        .set("Accept", "application/vnd.github+json")
        .call()
        .map_err(|error| UpdateError::Network(error.to_string()))?
        .into_string()
        .map_err(|error| UpdateError::Network(error.to_string()))?;
    release_from_json(&body)
}

/// Downloads a file, refusing anything larger than [`MAX_PACKAGE_BYTES`].
pub fn download(url: &str) -> Result<Vec<u8>, UpdateError> {
    let response = agent()
        .get(url)
        .call()
        .map_err(|error| UpdateError::Network(error.to_string()))?;
    let mut bytes = Vec::new();
    response
        .into_reader()
        .take(MAX_PACKAGE_BYTES + 1)
        .read_to_end(&mut bytes)
        .map_err(|error| UpdateError::Network(error.to_string()))?;
    if bytes.len() as u64 > MAX_PACKAGE_BYTES {
        return Err(UpdateError::TooLarge);
    }
    Ok(bytes)
}

/// Downloads the package for `release` and checks it against its checksum.
pub fn fetch_verified_package(release: &Release) -> Result<Vec<u8>, UpdateError> {
    let checksum_text = String::from_utf8_lossy(&download(&release.checksum_url)?).into_owned();
    let expected = parse_checksum(&checksum_text, &release.asset_name)
        .ok_or_else(|| UpdateError::Malformed("the checksum file is not usable".to_string()))?;
    let bytes = download(&release.asset_url)?;
    if sha256_hex(&bytes) != expected {
        return Err(UpdateError::ChecksumMismatch);
    }
    Ok(bytes)
}

/// The folder where verified packages wait for the reader.
pub fn updates_dir() -> PathBuf {
    match std::env::var("LOCALAPPDATA") {
        Ok(local) => PathBuf::from(local).join("abook").join("updates"),
        Err(_) => std::env::temp_dir().join("abook-updates"),
    }
}

/// Saves a verified package and its checksum in the updates folder. The
/// package is written under a temporary name first, so a half-written file is
/// never mistaken for an update.
pub fn stage(release: &Release, bytes: &[u8]) -> Result<PathBuf, UpdateError> {
    let dir = updates_dir();
    fs::create_dir_all(&dir).map_err(io_error)?;
    let path = dir.join(&release.asset_name);
    let partial = dir.join(format!("{}.partial", release.asset_name));
    fs::write(&partial, bytes).map_err(io_error)?;
    fs::rename(&partial, &path).map_err(io_error)?;
    let digest = sha256_hex(bytes);
    fs::write(checksum_path(&path), format!("{digest}  {}\n", release.asset_name))
        .map_err(io_error)?;
    Ok(path)
}

/// The checksum file that sits beside a staged package.
fn checksum_path(staged: &Path) -> PathBuf {
    let mut name = staged.as_os_str().to_owned();
    name.push(".sha256");
    PathBuf::from(name)
}

/// Checks that a staged package still matches the checksum saved with it.
pub fn verify_staged(staged: &Path) -> Result<(), UpdateError> {
    let saved = fs::read_to_string(checksum_path(staged)).map_err(io_error)?;
    let name = staged
        .file_name()
        .map(|name| name.to_string_lossy().into_owned())
        .unwrap_or_default();
    let expected = parse_checksum(&saved, &name)
        .ok_or_else(|| UpdateError::Malformed("the saved checksum is not usable".to_string()))?;
    let bytes = fs::read(staged).map_err(io_error)?;
    if sha256_hex(&bytes) == expected {
        Ok(())
    } else {
        Err(UpdateError::ChecksumMismatch)
    }
}

/// Whether the running program can be replaced where it stands. The check
/// writes and removes a probe file in the program's folder.
pub fn can_replace(target: &Path) -> bool {
    let Some(dir) = target.parent() else {
        return false;
    };
    let probe = dir.join(".abook-write-probe");
    match fs::File::create(&probe) {
        Ok(_) => {
            let _ = fs::remove_file(&probe);
            true
        }
        Err(_) => false,
    }
}

/// Quotes a value as a PowerShell single-quoted string.
fn ps_quote(value: &str) -> String {
    format!("'{}'", value.replace('\'', "''"))
}

/// The PowerShell script that replaces the program once it has exited, and
/// starts the new version. It waits for `process_id`, retries the copy for
/// about a minute, and keeps the staged package if the copy never succeeds.
pub fn helper_script(process_id: u32, staged: &Path, target: &Path) -> String {
    format!(
        "$ErrorActionPreference = 'SilentlyContinue'\n\
         Wait-Process -Id {process_id} -Timeout 60\n\
         $source = {source}\n\
         $target = {target}\n\
         $copied = $false\n\
         for ($i = 0; $i -lt 120 -and -not $copied; $i++) {{\n\
         \x20   try {{\n\
         \x20       Copy-Item -LiteralPath $source -Destination $target -Force -ErrorAction Stop\n\
         \x20       $copied = $true\n\
         \x20   }} catch {{\n\
         \x20       Start-Sleep -Milliseconds 500\n\
         \x20   }}\n\
         }}\n\
         if ($copied) {{ Start-Process -FilePath $target }}\n",
        source = ps_quote(&staged.display().to_string()),
        target = ps_quote(&target.display().to_string()),
    )
}

/// Replaces the program at `target` with the staged package and starts it
/// again. The caller must close the program straight after this returns `Ok`,
/// because the replacement only runs once the program has exited.
pub fn apply_and_restart(staged: &Path, target: &Path) -> Result<(), UpdateError> {
    verify_staged(staged)?;
    if !can_replace(target) {
        return Err(UpdateError::NeedsAdministrator(staged.to_path_buf()));
    }
    let script = staged.with_extension("ps1");
    fs::write(&script, helper_script(std::process::id(), staged, target)).map_err(io_error)?;

    let mut command = Command::new("powershell.exe");
    command
        .args(["-NoProfile", "-ExecutionPolicy", "Bypass", "-WindowStyle", "Hidden", "-File"])
        .arg(&script);
    #[cfg(windows)]
    {
        use std::os::windows::process::CommandExt;
        // CREATE_NO_WINDOW: start the helper without a console window.
        command.creation_flags(0x0800_0000);
    }
    command.spawn().map_err(io_error)?;
    Ok(())
}

/// Messages sent from the background threads.
enum Message {
    Checked(Result<Release, UpdateError>),
    Downloaded(Result<PathBuf, UpdateError>),
}

/// What the updater is doing, in the words the reader sees.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Status {
    /// No check has been made in this session.
    NotChecked,
    /// A check is running.
    Checking,
    /// The installed version is the newest release.
    UpToDate,
    /// A newer release exists and has not been downloaded.
    Available,
    /// The newer release is being downloaded and checked.
    Downloading,
    /// The newer release is downloaded, verified and waiting to be installed.
    Ready,
    /// The last step did not finish; the message says why.
    Failed(String),
}

/// The update state machine. It runs network work on background threads and
/// is polled from the interface each frame.
pub struct Updater {
    installed: Version,
    repository: String,
    /// What the updater is doing.
    pub status: Status,
    /// The newest published release, once a check has succeeded.
    pub latest: Option<Release>,
    /// The verified package, once it has been downloaded.
    pub staged: Option<PathBuf>,
    receiver: Option<Receiver<Message>>,
    last_check: Option<Instant>,
    download_when_found: bool,
}

impl Updater {
    /// Creates an updater for `installed` (the running version) that reads
    /// releases from `repository`.
    pub fn new(installed: &str, repository: &str) -> Self {
        let installed = Version::parse(installed).unwrap_or(Version {
            numbers: vec![0],
            pre: None,
        });
        Self {
            installed,
            repository: repository.to_string(),
            status: Status::NotChecked,
            latest: None,
            staged: None,
            receiver: None,
            last_check: None,
            download_when_found: false,
        }
    }

    /// The version of the running program.
    pub fn installed(&self) -> &Version {
        &self.installed
    }

    /// Whether a background step is running.
    pub fn is_busy(&self) -> bool {
        self.receiver.is_some()
    }

    /// Whether the newest release is newer than the running program.
    pub fn update_available(&self) -> bool {
        self.latest
            .as_ref()
            .is_some_and(|release| release.version > self.installed)
    }

    /// Starts a check. When `download_when_found` is set, a newer release is
    /// downloaded straight away.
    pub fn check(&mut self, download_when_found: bool) {
        if self.is_busy() {
            return;
        }
        self.status = Status::Checking;
        self.download_when_found = download_when_found;
        self.last_check = Some(Instant::now());
        let repository = self.repository.clone();
        let (sender, receiver) = mpsc::channel();
        self.receiver = Some(receiver);
        thread::spawn(move || {
            let _ = sender.send(Message::Checked(latest_release(&repository)));
        });
    }

    /// Downloads the newer release that the last check found.
    pub fn download(&mut self) {
        if self.is_busy() || !self.update_available() {
            return;
        }
        let Some(release) = self.latest.clone() else {
            return;
        };
        self.status = Status::Downloading;
        let (sender, receiver) = mpsc::channel();
        self.receiver = Some(receiver);
        thread::spawn(move || {
            let result = fetch_verified_package(&release).and_then(|bytes| stage(&release, &bytes));
            let _ = sender.send(Message::Downloaded(result));
        });
    }

    /// Runs the automatic part of the chosen mode. In manual mode nothing
    /// happens. Otherwise a check runs at the first call and then once a day.
    pub fn tick(&mut self, mode: UpdateMode) {
        if mode == UpdateMode::Manual || self.is_busy() {
            return;
        }
        let due = self
            .last_check
            .map_or(true, |at| at.elapsed() >= CHECK_INTERVAL);
        if due {
            self.check(true);
        }
    }

    /// Collects the result of a background step, if one has finished.
    pub fn poll(&mut self) {
        let Some(receiver) = self.receiver.as_ref() else {
            return;
        };
        match receiver.try_recv() {
            Ok(message) => {
                self.receiver = None;
                self.apply(message);
            }
            Err(TryRecvError::Empty) => {}
            Err(TryRecvError::Disconnected) => {
                self.receiver = None;
                self.status = Status::Failed("The update check stopped unexpectedly.".to_string());
            }
        }
    }

    fn apply(&mut self, message: Message) {
        match message {
            Message::Checked(Ok(release)) => {
                let newer = release.version > self.installed;
                self.latest = Some(release);
                if newer {
                    self.status = Status::Available;
                    if self.download_when_found {
                        self.download();
                    }
                } else {
                    self.status = Status::UpToDate;
                }
            }
            Message::Checked(Err(error)) => self.status = Status::Failed(error.to_string()),
            Message::Downloaded(Ok(path)) => {
                self.staged = Some(path);
                self.status = Status::Ready;
            }
            Message::Downloaded(Err(error)) => self.status = Status::Failed(error.to_string()),
        }
    }

    /// Replaces the program at `target` with the downloaded package and starts
    /// it again. On `Ok` the caller must close the program at once.
    pub fn install(&mut self, target: &Path) -> Result<(), UpdateError> {
        let Some(staged) = self.staged.clone() else {
            return Err(UpdateError::Io("no update has been downloaded".to_string()));
        };
        match apply_and_restart(&staged, target) {
            Ok(()) => Ok(()),
            Err(error) => {
                self.status = Status::Failed(error.to_string());
                Err(error)
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn version(raw: &str) -> Version {
        Version::parse(raw).expect("a version")
    }

    #[test]
    fn versions_compare_by_number_not_by_text() {
        assert!(version("v0.2.0") > version("0.1.9"));
        assert!(version("1.10.0") > version("1.9.0"));
        assert_eq!(version("1.0"), version("1.0.0"));
    }

    #[test]
    fn a_release_without_a_suffix_is_newer_than_the_same_numbers_with_one() {
        assert!(version("1.0.0") > version("1.0.0-alpha"));
        assert!(version("1.0.0-beta") > version("1.0.0-alpha"));
    }

    #[test]
    fn text_that_is_not_a_version_is_refused() {
        assert!(Version::parse("latest").is_none());
        assert!(Version::parse("1.x.0").is_none());
        assert!(Version::parse("").is_none());
    }

    #[test]
    fn a_version_prints_without_its_leading_v() {
        assert_eq!(version("v1.2.3-alpha").to_string(), "1.2.3-alpha");
    }

    #[test]
    fn update_modes_round_trip_and_manual_is_the_default() {
        assert_eq!(UpdateMode::default(), UpdateMode::Manual);
        for mode in [
            UpdateMode::Manual,
            UpdateMode::Download,
            UpdateMode::DownloadAndInstall,
        ] {
            assert_eq!(UpdateMode::from_id(mode.id()), mode);
        }
        assert_eq!(UpdateMode::from_id("something else"), UpdateMode::Manual);
    }

    const RELEASE: &str = r#"{
        "tag_name": "v0.2.0",
        "draft": false,
        "assets": [
            {"name": "abook-desktop-v0.2.0-windows-x64.exe.sha256",
             "browser_download_url": "https://example.test/sum"},
            {"name": "abook-desktop-v0.2.0-windows-x64.exe",
             "browser_download_url": "https://example.test/exe"},
            {"name": "abook-of-life-v0.2.0.apk",
             "browser_download_url": "https://example.test/apk"}
        ]
    }"#;

    #[test]
    fn the_windows_package_and_its_checksum_are_found() {
        let release = release_from_json(RELEASE).expect("a release");
        assert_eq!(release.tag, "v0.2.0");
        assert_eq!(release.asset_name, "abook-desktop-v0.2.0-windows-x64.exe");
        assert_eq!(release.asset_url, "https://example.test/exe");
        assert_eq!(release.checksum_url, "https://example.test/sum");
    }

    #[test]
    fn a_draft_release_is_refused() {
        let draft = RELEASE.replace("\"draft\": false", "\"draft\": true");
        assert_eq!(release_from_json(&draft), Err(UpdateError::Draft));
    }

    #[test]
    fn a_release_without_a_windows_package_is_refused() {
        let apk_only = r#"{"tag_name": "v0.2.0", "assets": [
            {"name": "abook-of-life-v0.2.0.apk", "browser_download_url": "https://example.test/apk"}
        ]}"#;
        assert_eq!(release_from_json(apk_only), Err(UpdateError::NoPackage));
    }

    #[test]
    fn a_tag_that_is_not_a_version_is_refused() {
        let bad = RELEASE.replace("v0.2.0", "nightly");
        assert!(matches!(
            release_from_json(&bad),
            Err(UpdateError::Malformed(_))
        ));
    }

    #[test]
    fn the_checksum_is_read_from_both_common_layouts() {
        let digest = "a".repeat(64);
        let with_name = format!("{digest}  pkg.exe\n");
        assert_eq!(parse_checksum(&with_name, "pkg.exe"), Some(digest.clone()));
        assert_eq!(parse_checksum(&digest, "pkg.exe"), Some(digest.clone()));
        assert_eq!(parse_checksum(&format!("{digest} *pkg.exe"), "pkg.exe"), Some(digest.clone()));
    }

    #[test]
    fn a_checksum_for_another_file_or_a_short_digest_is_refused() {
        let digest = "b".repeat(64);
        assert_eq!(parse_checksum(&format!("{digest}  other.exe"), "pkg.exe"), None);
        assert_eq!(parse_checksum("abc123  pkg.exe", "pkg.exe"), None);
    }

    #[test]
    fn sha256_matches_the_published_test_vector() {
        assert_eq!(
            sha256_hex(b"abc"),
            "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
        );
    }

    #[test]
    fn the_helper_script_quotes_paths_with_apostrophes() {
        let script = helper_script(
            42,
            Path::new(r"C:\Users\Ann's\updates\pkg.exe"),
            Path::new(r"C:\Apps\abook-desktop.exe"),
        );
        assert!(script.contains("Wait-Process -Id 42"));
        assert!(script.contains(r"$source = 'C:\Users\Ann''s\updates\pkg.exe'"));
        assert!(script.contains(r"$target = 'C:\Apps\abook-desktop.exe'"));
    }

    #[test]
    fn a_newer_release_is_offered_and_an_equal_one_is_not() {
        let mut updater = Updater::new("0.1.0", "owner/repo");
        updater.apply(Message::Checked(Ok(release_with_tag("v0.2.0"))));
        assert_eq!(updater.status, Status::Available);
        assert!(updater.update_available());

        let mut current = Updater::new("0.2.0", "owner/repo");
        current.apply(Message::Checked(Ok(release_with_tag("v0.2.0"))));
        assert_eq!(current.status, Status::UpToDate);
        assert!(!current.update_available());
    }

    #[test]
    fn a_failed_check_is_reported_and_not_hidden() {
        let mut updater = Updater::new("0.1.0", "owner/repo");
        updater.apply(Message::Checked(Err(UpdateError::Network("offline".into()))));
        assert!(matches!(updater.status, Status::Failed(_)));
        assert!(!updater.update_available());
    }

    #[test]
    fn manual_mode_never_starts_a_check_by_itself() {
        let mut updater = Updater::new("0.1.0", "owner/repo");
        updater.tick(UpdateMode::Manual);
        assert_eq!(updater.status, Status::NotChecked);
        assert!(!updater.is_busy());
    }

    fn release_with_tag(tag: &str) -> Release {
        Release {
            tag: tag.to_string(),
            version: Version::parse(tag).expect("a version"),
            asset_name: "pkg.exe".to_string(),
            asset_url: "https://example.test/exe".to_string(),
            checksum_url: "https://example.test/sum".to_string(),
        }
    }
}
