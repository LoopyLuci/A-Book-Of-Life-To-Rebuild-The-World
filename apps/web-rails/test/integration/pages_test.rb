require "test_helper"

# The pages of the reader.
class PagesTest < ActionDispatch::IntegrationTest
  test "the home page lists the sixteen domains with their entry counts" do
    get root_path

    assert_response :success
    assert_select "h1", 1
    assert_select ".domain-card", 16
    assert_select ".domain-card a", 16
    assert_select ".domain-card .domain-count", 16
    assert_match "Survival", response.body
    assert_match "13 entries", response.body
  end

  test "the domain index lists every domain" do
    get domains_path

    assert_response :success
    assert_select ".domain-card", 16
  end

  test "a domain page lists its entries" do
    get domain_path("survival")

    assert_response :success
    assert_select "h1", "Survival"
    assert_select ".entry-list li", minimum: 1
    assert_match "Making Fire", response.body
  end

  test "an unknown domain is not found" do
    get domain_path("does-not-exist")

    assert_response :not_found
  end

  test "an entry page shows the metadata, the body, the tags, the sources and the related entries" do
    get entry_path("survival", "making-fire")

    assert_response :success
    assert_select "h1", "Making Fire"
    assert_select ".entry-meta .pill", minimum: 3
    assert_select ".verification .verification-status", "Draft"
    assert_select ".entry-body h2", minimum: 1
    assert_select ".entry-body p", minimum: 1
    assert_select ".tag-list li", minimum: 1
    assert_select ".source-list li", minimum: 1
    assert_select ".entry-footer a[href=?]", "/entries/survival/water-purification"
  end

  test "an unknown entry is not found" do
    get entry_path("survival", "does-not-exist")

    assert_response :not_found
  end

  test "the search page ranks the results" do
    get search_path(q: "making fire")

    assert_response :success
    assert_select ".search-result", minimum: 1
    assert_select ".search-result h3 a", text: "Making Fire"
  end

  test "the search page filters by domain, safety level and difficulty" do
    get search_path(q: "water", domain: "survival")

    assert_response :success
    assert_select ".search-result", minimum: 1
    assert_select ".search-result .meta a", text: "survival"

    get search_path(q: "water", safety: "red")
    assert_response :success
    assert_select ".search-result .pill-red", minimum: 1

    get search_path(q: "water", difficulty: "novice")
    assert_response :success
    assert_select ".search-result .pill", minimum: 1
  end

  test "the search page says when nothing matches" do
    get search_path(q: "zzzzzzzznotanentry")

    assert_response :success
    assert_select ".search-result", 0
    assert_select ".empty", 1
  end

  test "the about page shows the version and the disclaimer" do
    get about_path

    assert_response :success
    assert_match(/0\.1\.0-alpha/, response.body)
    assert_match "Not professional advice of any kind", response.body
    assert_match "Local law, standards and primary sources always win", response.body
  end

  test "the pages are marked up for accessibility" do
    get root_path

    assert_select "html[lang=en][dir=ltr]"
    assert_select "a.skip-link[href=?]", "#main"
    assert_select "main#main"
    assert_select "header.site-header"
    assert_select "footer.site-footer"
    assert_select "nav", minimum: 1
    assert_select "label[for=header-query]"
    assert_select "input#header-query[name=q]"
  end

  test "the entry body is escaped, so that the corpus cannot inject markup" do
    get entry_path("survival", "making-fire")

    assert_response :success
    assert_select ".entry-body script", 0
  end

  test "the sitemap and the robots file are served" do
    get "/sitemap.xml"

    assert_response :success
    assert_match "urlset", response.body
    assert_match "/entries/survival/making-fire", response.body

    get "/robots.txt"

    assert_response :success
    assert_match "Sitemap:", response.body
  end

  test "the health check reports that the application is up" do
    get "/up"

    assert_response :success
  end
end
