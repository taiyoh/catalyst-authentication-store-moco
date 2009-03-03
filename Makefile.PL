use inc::Module::Install;
name 'Catalyst-Authentication-Store-MoCo';
all_from 'lib/Catalyst/Authentication/Store/MoCo.pm';

# requires '';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
