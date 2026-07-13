local util = {}

--- GitHub repository info
util.OWNER = "iii-hq"
util.REPO = "iii"

--- GitHub API base URL
util.GH_API_BASE = "https://api.github.com"

--- GitHub Releases download base URL
util.GH_DOWNLOAD_BASE = "https://github.com/" .. util.OWNER .. "/" .. util.REPO .. "/releases/download"

--- Map RUNTIME.osType + RUNTIME.archType to Rust target triple.
--- @return string target triple (e.g. "x86_64-unknown-linux-gnu")
function util.get_target_triple()
    local os_type = string.lower(RUNTIME.osType)
    local arch_type = string.lower(RUNTIME.archType)

    if os_type == "darwin" then
        if arch_type == "amd64" then
            return "x86_64-apple-darwin"
        elseif arch_type == "arm64" then
            return "aarch64-apple-darwin"
        end
    elseif os_type == "linux" then
        if arch_type == "amd64" then
            return "x86_64-unknown-linux-gnu"
        elseif arch_type == "arm64" then
            return "aarch64-unknown-linux-gnu"
        elseif arch_type == "arm" then
            return "armv7-unknown-linux-gnueabihf"
        end
    elseif os_type == "windows" then
        if arch_type == "amd64" then
            return "x86_64-pc-windows-msvc"
        elseif arch_type == "arm64" then
            return "aarch64-pc-windows-msvc"
        end
    end

    -- fallback: try to construct from raw values
    return arch_type .. "-unknown-" .. os_type .. "-gnu"
end

--- Get file extension for the current OS.
--- @return string ".tar.gz" or ".zip"
function util.get_file_extension()
    if string.lower(RUNTIME.osType) == "windows" then
        return ".zip"
    end
    return ".tar.gz"
end

--- Determine the GitHub release tag for a given version.
--- Alpha versions use "iii-alpha/v{version}", others use "iii/v{version}".
--- @param version string
--- @return string tag
function util.get_tag_for_version(version)
    if string.find(version, "alpha") then
        return "iii-alpha/v" .. version
    end
    return "iii/v" .. version
end

--- Construct the download URL for a specific version and target triple.
--- GitHub handles slashes in tag names natively — the tag is everything
--- between "/download/" and the last "/" in the path.
--- @param version string
--- @param target_triple string
--- @param ext string file extension
--- @return string download URL
function util.get_download_url(version, target_triple, ext)
    local tag = util.get_tag_for_version(version)
    local filename = "iii-" .. target_triple .. ext
    return util.GH_DOWNLOAD_BASE .. "/" .. tag .. "/" .. filename
end

--- Construct the checksum URL for a specific version, target triple and extension.
--- The sha256 file name is the archive basename (without archive extension) + ".sha256".
--- e.g. "iii-aarch64-apple-darwin.sha256" (not "iii-aarch64-apple-darwin.tar.gz.sha256")
--- @param version string
--- @param target_triple string
--- @param ext string file extension (unused — sha256 uses basename only)
--- @return string checksum URL
function util.get_checksum_url(version, target_triple)
    local tag = util.get_tag_for_version(version)
    local basename = "iii-" .. target_triple
    return util.GH_DOWNLOAD_BASE .. "/" .. tag .. "/" .. basename .. ".sha256"
end

--- Parse SHA256 checksum from a .sha256 file content.
--- The file format is either "sha256:<hash>" or "<hash>  <filename>" or just the hash.
--- @param content string
--- @return string|nil sha256 hash
function util.parse_sha256(content)
    if not content then
        return nil
    end
    -- Trim whitespace
    content = string.gsub(content, "^%s+", "")
    content = string.gsub(content, "%s+$", "")

    -- Format: "sha256:<hex>" (GitHub UI display format)
    local hash = string.match(content, "^sha256:(%x+)$")
    if hash then
        return hash
    end

    -- Format: "<hex>  <filename>" or "<hex> <filename>"
    hash = string.match(content, "^(%x+)%s+%S+")
    if hash then
        return hash
    end

    -- Format: just the hex hash
    hash = string.match(content, "^(%x+)$")
    if hash then
        return hash
    end

    return nil
end

--- Parse version from a GitHub release tag name.
--- Tags are like "iii/v0.21.4" or "iii-alpha/v0.21.4-alpha.1".
--- @param tag_name string
--- @return string|nil version
function util.parse_version_from_tag(tag_name)
    -- Match "iii/v0.21.4" or "iii-alpha/v0.21.4-alpha.1"
    local version = string.match(tag_name, "^iii[^/]*/v(.+)$")
    return version
end

--- Compare two version strings for sorting (descending: newest first).
--- @param a table { version = string }
--- @param b table { version = string }
--- @return boolean true if a.version > b.version
function util.compare_versions(a, b)
    local v1 = a.version
    local v2 = b.version

    -- Split into dot-separated parts (e.g. "0.21.4-next.2" → {"0","21","4","next","2"})
    local function split_version(v)
        local parts = {}
        for part in string.gmatch(v, "[^.]+") do
            table.insert(parts, part)
        end
        return parts
    end

    local parts1 = split_version(v1)
    local parts2 = split_version(v2)

    for i = 1, math.max(#parts1, #parts2) do
        local p1 = parts1[i]
        local p2 = parts2[i]

        -- One version ended: the shorter one is a release (no pre-release suffix)
        -- In descending order, release > pre-release of the same base version
        if p1 == nil then
            return true  -- a is shorter → a is a release → a comes first
        end
        if p2 == nil then
            return false -- b is shorter → b is a release → b comes first
        end

        local n1 = tonumber(p1)
        local n2 = tonumber(p2)
        if n1 and n2 then
            if n1 > n2 then return true end
            if n1 < n2 then return false end
        else
            -- String comparison for pre-release suffixes ("next" > "alpha")
            if p1 > p2 then return true end
            if p1 < p2 then return false end
        end
    end

    return false
end

return util
