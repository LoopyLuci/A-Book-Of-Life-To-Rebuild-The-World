require "test_helper"

# The preferences of the reader: the language, the theme and the recently
# read entries.
class PreferencesTest < ActionDispatch::IntegrationTest
  test "the language switcher switches the interface strings" do
    post settings_language_path, params: { lang: "fr", return_to: "/" }

    assert_redirected_to "/"
    assert_equal "fr", cookies[:abook_lang]

    follow_redirect!

    assert_select "html[lang=fr]"
    assert_match "Domaines", response.body
  end

  test "the language switcher returns to the page it was used on" do
    post settings_language_path, params: { lang: "de", return_to: "/domains/survival" }

    assert_redirected_to "/domains/survival"
  end

  test "an unknown language falls back to English" do
    post settings_language_path, params: { lang: "xx", return_to: "/" }

    get root_path

    assert_select "html[lang=en]"
  end

  test "arabic is written from right to left" do
    post settings_language_path, params: { lang: "ar", return_to: "/" }

    get root_path

    assert_select "html[lang=ar][dir=rtl]"
  end

  test "the theme override is stored in a cookie" do
    post settings_theme_path, params: { theme: "dark", return_to: "/" }

    assert_response :redirect
    assert_equal "dark", cookies[:abook_theme]

    get root_path

    assert_select "html[data-theme=dark]"
  end

  test "the system preference is followed when there is no override" do
    get root_path

    assert_select "html[data-theme=system]"
  end

  test "the theme override can be removed again" do
    post settings_theme_path, params: { theme: "dark", return_to: "/" }
    post settings_theme_path, params: { theme: "system", return_to: "/" }

    get root_path

    assert_select "html[data-theme=system]"
  end

  test "the switcher refuses to send the reader to another site" do
    post settings_language_path, params: { lang: "fr", return_to: "https://example.com/" }

    assert_redirected_to root_path

    post settings_theme_path, params: { theme: "dark", return_to: "//example.com/" }

    assert_redirected_to root_path
  end

  test "the recently read list remembers the entries that were read" do
    get entry_path("survival", "making-fire")

    assert_response :success
    assert cookies[:abook_recent].present?

    get root_path

    assert_select ".recent-list li", minimum: 1
    assert_match "Making Fire", response.body
  end

  test "the recently read list keeps the newest entry first" do
    get entry_path("survival", "making-fire")
    get entry_path("survival", "finding-water")

    get root_path

    assert_select ".recent-list li", 2
    assert_select ".recent-list li:first-child", text: /Finding Water/
  end
end
