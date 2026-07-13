--- Each SDK may have different environment variable configurations.
--- This allows plugins to define custom environment variables (including PATH settings)
--- Note: Be sure to distinguish between environment variable settings for different platforms!
--- @param ctx table Context information
--- @field ctx.path string SDK installation directory
function PLUGIN:EnvKeys(ctx)
    local install_path = ctx.path

    -- The iii binary is extracted to the root of the installation directory
    -- On Unix: the binary is at <install_path>/iii
    -- On Windows: the binary is at <install_path>/iii.exe
    -- Add the installation directory to PATH so the iii command is available
    return {
        {
            key = "PATH",
            value = install_path
        },
    }
end
