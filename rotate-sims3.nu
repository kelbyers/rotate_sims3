use std log

def get-base [save_path] {
    let type = ($save_path | path type)
    let directory = ($save_path | path dirname)
    log debug $"save_path: ($save_path)"
    log debug $"type: ($type)"
    log debug $"directory: ($directory)"

    if $type == "file" {
        return $directory
    } else if ($save_path | str ends-with "\\") {
        return ($save_path | str substring 0..-2)
    } else {
        return $save_path
    }
}

def split-root-extension [save_path] {
    let base = (get-base $save_path | path parse)
    let root = ($base.stem | str replace -r '( - [-0-9]*)|(\d+)$' '')
    return ({
        parent: $base.parent,
        root: $root,
        extension: $base.extension
    })
}

def get-candidates [base] {
    (
        ls $base.parent |
        where type == 'dir' |
        get name |
        str replace ($base.parent + '\') ''
        |
        where {|r| $r =~ $"^($base.root)\(\\d+)?\\.($base.extension)\(\\.backup)?$"}
        # get name |
        # path parse |
        # where extension == 'sims3'
    )
}

def main [
    save_path
    --once
    --timeStampAll
] {
    if not ($save_path | path exists) {
        log error $"Does not exist: ($save_path)"
        exit 2
    }
    let base = (split-root-extension $save_path)

    while true {
        let candidates = (get-candidates $base)

        print $candidates
        exit 0
    }
}
