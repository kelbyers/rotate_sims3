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

export def split-root-extension [save_path] {
    let base = (
        get-base $save_path
        | path parse # split into components
        | each {|p| # split off '.backup' extenion and report the real one
            if ($p.extension == 'backup') {
                let u = ($p.stem | path parse) # get the non-backup extension
                return (
                    $p
                    | update stem $u.stem # stem with extension removed
                    | update extension $u.extension # real extension
                )
            } else $p # not a backup, so just pass it through
        }
        | update stem {|p|
            # strip off timestamp or save instance number
            ($p.stem | str replace -r '( - [-0-9]*)|(\d+)$' '')
        }
    )

    log debug $"base: ($base)"

    if ($base.extension != 'sims3') {
        # after processing it above, this is not a sims3 backup directory
        let span = (metadata $save_path).span

        # throw an error
        error make {
            msg: "Cannot rotate non-sims3 saves"
            label: {
                text: "need a '.sims3' directory"
                span: $span
            }
        }
    }

    return ({
        parent: $base.parent,
        root: $base.stem,
        extension: $base.extension
    })
}

export def get-candidates [base] {
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
        ls -l $base.parent |
        where type == 'dir' |
        where {|r| $r.name =~ $pattern } |
        select name created
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
