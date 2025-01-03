use ./find-tests.nu

export def main [test_dir] {
    let sources = (find-tests $test_dir)
    print "Tests found:"
    $sources | print
}
