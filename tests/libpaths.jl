function add_to_loadpath!(paths...)
    for path in paths
        if ! (path in LOAD_PATH)
            push!(LOAD_PATH, path)
        end
    end
end

add_to_loadpath!(pwd() * "/src")
