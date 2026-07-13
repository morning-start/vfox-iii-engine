local util = require("util")
local http = require("http")

--- Cache for available versions to avoid repeated HTTP requests within the same session
local available_cache = nil

--- Return all available versions provided by this plugin by scraping
--- the GitHub releases page HTML (GitHub API is often rate-limited).
--- @param ctx table Empty table used as context, for future extension
--- @return table Descriptions of available versions and accompanying tool descriptions
function PLUGIN:Available(ctx)
    if available_cache then
        return available_cache
    end

    -- Use the releases HTML page instead of the API (API is often rate-limited to 403)
    local resp, err = http.get({
        url = "https://github.com/iii-hq/iii/releases",
    })

    if err ~= nil or resp.status_code ~= 200 then
        return {}
    end

    local body = resp.body
    local result = {}
    local seen = {}

    -- Parse tag names from HTML links like:
    --   href="/iii-hq/iii/releases/tag/iii%2Fv0.21.4"
    --   href="/iii-hq/iii/releases/tag/iii-alpha%2Fv0.21.4-alpha.1"
    -- The tag name is URL-encoded with %2F representing /
    local pattern = '/iii%-hq/iii/releases/tag/(iii[^"]+)'
    for tag_encoded in string.gmatch(body, pattern) do
        -- URL-decode: replace %2F with /
        local tag = string.gsub(tag_encoded, "%%2F", "/")

        -- Parse version from tag (e.g. "iii/v0.21.4" -> "0.21.4")
        local version = util.parse_version_from_tag(tag)
        if version and not seen[version] then
            seen[version] = true
            local item = {
                version = version,
                note = "",
            }
            -- Mark pre-release versions (containing "next" or "alpha")
            if string.find(version, "next") or string.find(version, "alpha") then
                item.note = "pre-release"
            end
            table.insert(result, item)
        end
    end

    -- Sort versions: newest first
    table.sort(result, util.compare_versions)

    available_cache = result
    return result
end
