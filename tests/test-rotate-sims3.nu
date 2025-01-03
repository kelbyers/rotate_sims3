use std/assert
use std/log

use ../rotate-sims3.nu *

def main [] {
    print "Running tests..."

    let test_commands = (
        scope commands
            | where ($it.type == "custom")
                and ($it.name | str starts-with "test ")
                and not ($it.description | str starts-with "ignore")
            | get name
            | each { |test| [$"print 'Running test: ($test)'", $test] } | flatten
            | str join "; "
    )

    nu --commands $"source ($env.CURRENT_FILE); ($test_commands)"
    print "Tests completed successfully"
}

def setup-dirs [root ...dirs] {
    $dirs | each {|d|
        let dir = ([$root $d] | path join)
        mkdir $dir
        $dir
    }
}

def run-in-tmpdir [$cl] {
    let root = (mktemp --directory)
    do $cl $root
    rm --recursive --force $root
}

# ignore
def "test run-in-tmpdir" [] {
    run-in-tmpdir {|root|
        assert ($root | path exists)
    }
}

# ignore
def "test no-dir" [] {
    run-in-tmpdir {|root|
        mut passed = true
        try {
            rm --recursive --force $root
            assert ($root | path exists)
            $passed = false
        }
        assert $passed
    }
}

# ignore
def "test setup-dirs creates sub-directories" [] {
    run-in-tmpdir {|root|
        setup-dirs $root a b c
        assert ([$root a] | path join | path exists)
        assert ([$root b] | path join | path exists)
        assert ([$root c] | path join | path exists)
    }
}

# ignore
def "test setup-dirs returns list" [] {
    run-in-tmpdir {|root|
        let dirs = (setup-dirs $root a b c)
        let expected = (
            [a b c] | each {|d| [$root $d] | path join}
        )

        assert equal $dirs $expected
    }
}

# no ignore
def "test get-base from a directory" [] {
    run-in-tmpdir {|root|
        let dir_a = (setup-dirs $root a).0
        let base = (get-base $dir_a)
        log debug $"root: ($root)"
        log debug $"base: ($base)"
        assert equal $base $dir_a
    }
}

# no ignore
def "test get-base from a directory with a trailing slash" [] {
    run-in-tmpdir {|root|
        let dir_a = (setup-dirs $root a).0
        let dir_a_extra = $"($dir_a)/"
        let base = (get-base $dir_a_extra)
        log debug $"root: ($root)"
        log debug $"dir_a_extra: ($dir_a_extra)"
        log debug $"base: ($base)"
        assert equal $base $dir_a
    }
}

def "test get-base-from-file" [] {
    run-in-tmpdir {|root|
        let dir_a = (setup-dirs $root a).0
        let file_a = ([$dir_a f.txt] | path join)
        touch $file_a

        let base = (get-base $file_a)

        log debug $"root: ($root)"
        log debug $"base: ($base)"
        log debug $"type: ($file_a | path type)"

        assert equal $base $dir_a
    }
}
