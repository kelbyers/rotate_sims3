export def main [test_dir] {
    cd $test_dir
    ls **/* | where type == file | where name =~ '_test.nu'
}
