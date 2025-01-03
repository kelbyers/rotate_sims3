use std/log

export def get-base [save_path] {
    let type = ($save_path | path type)
    let directory = ($save_path | path dirname)
    log debug $"save_path: ($save_path)"
    log debug $"type: ($type)"
    log debug $"directory: ($directory)"

    if $type == "file" {
        return $directory
    } else {
        return ($save_path | path split | path join)
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
    let root = ([$base.parent $base.root] | str join '\')
    let pattern = (
        '^' +
        ($root | str replace --all '\' '\\') +
        '(\d+)?\.' +
        $base.extension +
        '(\.backup)?$'
    )
    log debug $"root: ($root)"
    log debug $"pattern: ($pattern)"
    (
        ls $base.parent |
        where type == 'dir' |
        where {|r| $r.name =~ $pattern } |
        select name modified
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
