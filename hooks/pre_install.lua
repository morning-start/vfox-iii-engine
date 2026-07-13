local http = require("http")
local util = require("util")

--- Returns pre-installation information for the iii engine: version, download URL, and checksum.
--- The download URL and SHA256 checksum are determined based on the current platform.
--- If checksum is provided, vfox will automatically verify it for you.
--- @param ctx table
--- @field ctx.version string User-input version
--- @return table Version information
function PLUGIN:PreInstall(ctx)
    local version = ctx.version

    -- Resolve "latest" to the actual latest version
    if version == "latest" then
        local lists = self:Available({})
        if #lists == 0 then
            error("No available versions found for iii engine")
        end
        version = lists[1].version
    end

    if version == nil then
        error("version not found for provided version " .. (ctx.version or "null"))
    end

    -- Determine platform-specific values
    local target_triple = util.get_target_triple()
    local ext = util.get_file_extension()

    -- Construct download URL and checksum URL
    local download_url = util.get_download_url(version, target_triple, ext)
    local checksum_url = util.get_checksum_url(version, target_triple)

    -- Fetch SHA256 checksum
    local sha256 = nil
    local resp, err = http.get({
        url = checksum_url,
    })
    if err == nil and resp.status_code == 200 then
        sha256 = util.parse_sha256(resp.body)
    end

    -- Append filename as URI fragment so vfox can detect the archive format
    -- This is needed because GitHub release URLs don't end with the filename directly
    -- (they contain the tag path). We add #/filename.ext to help vfox identify the format.
    local filename = "iii-" .. target_triple .. ext
    download_url = download_url .. "#/" .. filename

    local result = {
        version = version,
        url = download_url,
    }

    if sha256 then
        result.sha256 = sha256
    end

    return result
end
