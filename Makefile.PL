use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Devel::Leak::Object',
    VERSION_FROM => 'lib/Devel/Leak/Object.pm', # finds $VERSION
    AUTHOR       => 'A. U. Thor (a.u.thor@a.galaxy.far.far.away)',
    ABSTRACT     => '',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                    },
);
