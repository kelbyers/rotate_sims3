use std/assert
use std/log

use ../rotate-sims3.nu *

let ts_format = '%Y%m%d-%H%M%S'

def opt-filter [variable filt] {
    if (($variable in $env) and ($env | get $variable | is-not-empty)) {
        $in | filter $filt
    } else $in
}

def filter-tests [] {
    let test_list = (
        $in
        | where type == 'custom'
            and name =~ '(f-)?test '
            and not ($it.description | str starts-with "ignore")
        | opt-filter 'NUTESTS' {|t| $t.name | str contains $env.NUTESTS}
    )

    (
        $test_list
        | (where ($it.name | str starts-with 'f-test')
        | if ($in | is-not-empty) { $in } else $test_list)
    )
}


def get-tests [] {
    (scope commands | filter-tests)
}

def main [] {
    print "Running tests..."

    let test_commands = (
        get-tests
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
def "test opt-filter passes through" [] {
    if ('MADE_UP_VAR' in $env ) {hide-env MADE_UP_VAR}
    let source = [ab bc cd da]
    let got = ($source | opt-filter 'MADE_UP_VAR' {|i| $i | str contains $env.MADE_UP_VAR})
    assert equal $got $source
}

# ignore
def "test opt-filter filters from env variable" [] {
    $env.MADE_UP_VAR = 'c'
    let source = [ab bc cd da]
    let expected = [bc cd]
    let got = ($source | opt-filter 'MADE_UP_VAR' {|i| $i | str contains $env.MADE_UP_VAR})
    assert equal $got $expected
}

# ignore
def "test filter-tests" [] {
    hide-env NUTESTS
    let commands = [
        {name: 'doit',  type: 'special', description: ''}
        {name: 'doit2',  type: 'custom', description: ''}
        {name: "test one",  type: 'custom', description: ''}
        {name: "test two",  type: 'custom', description: ''}
        {name: "f-test focus",  type: 'special', description: ''}
    ]
    let expected = [
        {name: "test one",  type: 'custom', description: ''}
        {name: "test two",  type: 'custom', description: ''}
    ]
    let got = ($commands | filter-tests)
    assert equal $got $expected
}

# ignore
def "test filter-tests returns focus tests" [] {
    hide-env NUTESTS

    let commands = [
        {name: 'doit',  type: 'special', description: ''}
        {name: 'doit2',  type: 'custom', description: ''}
        {name: "test one",  type: 'custom', description: ''}
        {name: "test two",  type: 'custom', description: ''}
        {name: "f-test focus",  type: 'custom', description: ''}
        {name: "f-test two",  type: 'custom', description: ''}
    ]
    let expected = [
        {name: "f-test focus",  type: 'custom', description: ''}
        {name: "f-test two",  type: 'custom', description: ''}
    ]
    let got = ($commands | filter-tests)
    assert equal $got $expected
}

# ignore
def "test filter-tests ignores tests" [] {
    hide-env NUTESTS

    let commands = [
        {name: 'doit',  type: 'special', description: ''}
        {name: 'doit2',  type: 'custom', description: ''}
        {name: "test one",  type: 'custom', description: ''}
        {name: "test two",  type: 'custom', description: 'ignore'}
        {name: "f-test two",  type: 'custom', description: 'ignore'}
    ]
    let expected = [
        {name: "test one",  type: 'custom', description: ''}
    ]
    let got = ($commands | filter-tests)
    assert equal $got $expected
}

# ignore
def "test filter-tests ignores f-tests" [] {
    hide-env NUTESTS

    let commands = [
        {name: 'doit',  type: 'special', description: ''}
        {name: 'doit2',  type: 'custom', description: ''}
        {name: "test one",  type: 'custom', description: ''}
        {name: "test two",  type: 'custom', description: 'ignore'}
        {name: "f-test one",  type: 'custom', description: 'ignore'}
        {name: "f-test two",  type: 'custom', description: ''}
    ]
    let expected = [
        {name: "f-test two",  type: 'custom', description: ''}
    ]
    let got = ($commands | filter-tests)
    assert equal $got $expected
}

# ignore
def "test filter-tests uses opt-filter" [] {
    $env.NUTESTS = 'two'
    let commands = [
        {name: "test one",  type: 'custom', description: ''}
        {name: "test two",  type: 'custom', description: ''}
        {name: "test two with form",  type: 'custom', description: ''}
        {name: "f-test one",  type: 'custom', description: ''}
        {name: "f-test two",  type: 'custom', description: 'ignore'}
    ]
    let expected = [
        {name: "test two",  type: 'custom', description: ''}
        {name: "test two with form",  type: 'custom', description: ''}
    ]

    let got = ($commands | filter-tests)
    assert equal $got $expected
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
        assert error {||
            rm --recursive --force $root
            assert ($root | path exists)
        } $"($root) should not exist"
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

def "test get-base from file" [] {
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

def "test split-root-extension" [] {
    run-in-tmpdir {|root|
        let extension = 'sims3'
        let expected = 'a'
        let dir_a = (setup-dirs $root $"($expected).($extension)").0
        let split = (split-root-extension $dir_a)

        assert equal $root $split.parent
        assert equal $extension $split.extension
        assert equal $expected $split.root
    }
}

def "test split-root-extension numbered" [] {
    run-in-tmpdir {|root|
        let extension = 'sims3'
        let expected = 'a'
        let dir_a = (setup-dirs $root $"($expected)23.($extension)").0
        let split = (split-root-extension $dir_a)

        assert equal $root $split.parent
        assert equal $extension $split.extension
        assert equal $expected $split.root
    }
}

def "test split-root-extension with timestamp" [] {
    run-in-tmpdir {|root|
        let extension = 'sims3'
        let expected = 'a'
        let timestamp = (date now | format date '%Y%m%d-%H%M%S')
        let dir_a = (setup-dirs $root $"($expected) - ($timestamp).($extension)").0
        let split = (split-root-extension $dir_a)

        log debug $"dir_a: ($dir_a)"

        assert equal $root $split.parent
        assert equal $extension $split.extension
        assert equal $expected $split.root
    }
}

def "test split-root-extension fails for non sims3 save" [] {
    run-in-tmpdir {|root|
        let non_save = (setup-dirs $root a.ho).0

        assert error {||
            split-root-extension $non_save
        } "should not accept non-sims3 save"
    }
}

def "test split-root-extension fails for non sims3 backup" [] {
    run-in-tmpdir {|root|
        let non_save = (setup-dirs $root a.ho.backup).0

        assert error {||
            split-root-extension $non_save
        } "should not accept non-sims3 save"
    }
}

def "test split-root-extension for sims3.backup save" [] {
    run-in-tmpdir {|root|
        let extension = 'sims3'
        let expected = 'a'
        let backup_save = (setup-dirs $root a.sims3.backup).0

        let split = (split-root-extension $backup_save)

        assert equal $root $split.parent
        assert equal $extension $split.extension
        assert equal $expected $split.root

    }
}

def "test get-candidates" [] {
    run-in-tmpdir {|root|
        let base_candidates = [
            a.sims3
            a1.sims3
            a2.sims3
        ]
        let dirs = (setup-dirs $root ...$base_candidates)
        let base = (split-root-extension $dirs.0)
        let candidates = (get-candidates $base)

        assert equal ($candidates | get name | sort) ($dirs | sort)
    }
}

def "test get-candidates with other saves" [] {
    run-in-tmpdir {|root|
        let base_candidates = [
            a.sims3
            a1.sims3
            a2.sims3
        ]
        let dirs = (setup-dirs $root ...$base_candidates)
        let extras = (
            setup-dirs $root b.sims3 c.sims3 d.sims3 e.sims3.backup)
        let base = (split-root-extension $dirs.0)
        let candidates = (get-candidates $base)

        assert equal ($candidates | get name | sort) ($dirs | sort)
        assert ($extras | path exists | all {|p| $p})
    }
}

def "test get-candidates with backups" [] {
    run-in-tmpdir {|root|
        let base_candidates = [
            a.sims3
            a1.sims3
            a2.sims3
            a.sims3.backup
        ]
        let dirs = (setup-dirs $root ...$base_candidates)
        let base = (split-root-extension $dirs.0)
        let candidates = (get-candidates $base)

        log debug $"candidates: ($candidates | get name)"
        assert equal ($candidates | get name | sort) ($dirs | sort)
    }
}

#
def "test get-candidates has the name of the save" [] {
    run-in-tmpdir {|root|
        let extension = 'sims3'
        let expected = 'a'
        let dir_a = (setup-dirs $root $"($expected)23.($extension)").0

        let candidates = (get-candidates (split-root-extension $dir_a))
        let columns = ($candidates | columns)

        assert ('name' in $columns)
    }
}

def "test get-candidates has the created time of the save" [] {
    run-in-tmpdir {|root|
        let extension = 'sims3'
        let expected = 'a'
        let dir_a = (setup-dirs $root $"($expected)23.($extension)").0

        let candidates = (get-candidates (split-root-extension $dir_a))
        let columns = ($candidates | columns)

        log debug $"columns: ($columns)"
        assert ('created' in $columns)
    }
}

def add-time-stamps [dirs now] {
    let count = $dirs | length

    let format_ts = {|i|
        $now - ($i * 10sec) | format date $ts_format}

    (
        $dirs
        | path parse
        | enumerate
        | update item.stem {|i|
            $i.item.stem + ' - ' + (do $format_ts $i.index)}
        | get item
        | path join
    )
}

# ignore
def "test add-time-stamps" [] {
    let raw = (
        [a b]
        | each {|d| [z y x $d] | path join}
    )
    let dirs = ($raw | each {|d| $d + '.sims3'})
    let now = (date now)
    let ts = [
        ($now | format date $ts_format)
        (($now - 10sec) | format date $ts_format)
    ]

    let expected = [
        ($raw.0 + ' - ' + $ts.0 + '.sims3')
        ($raw.1 + ' - ' + $ts.1 + '.sims3')
    ]

    let got = (add-time-stamps $dirs $now)
    assert equal $got $expected
}

# no ignore
def "test get-candidates with timestamps" [] {
    run-in-tmpdir {|root|
        let base_candidates = [
            a.sims3
            a1.sims3
            a2.sims3
        ]
        let dirs = (setup-dirs $root ...$base_candidates)

        let extra_names = (
            add-time-stamps [a.sims3 a.sims3 a.sims3] (date now))
        let extra_dirs = (setup-dirs $root ...$extra_names)

        let base = (split-root-extension $dirs.0)
        let candidates = (get-candidates $base)

        log debug $"all: (ls $root | get name)"
        log debug $"candidates: ($candidates | get name)"
        assert equal ($candidates | get name | sort) ($dirs | sort)
    }
}

#
def "test get-timestamp-name" [] {
    let name = ([a b c d.sims3] | path join)
    let created = (1736039242 | into datetime -f %s | date to-timezone local)
    let timestamp = '20250104-190722'
    let expected = {
        name: ([a b c $"d - ($timestamp).sims3"] | path join)
        created: $created
    }

    let got = ( {name: $name created: $created} | get-timestamp-name)
    assert equal $got $expected
}
