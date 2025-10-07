#/usr/bin/env perl
use v5.12;
use strict; use warnings;
use File::Spec::Functions;
use File::Copy;

my $builddir = "build";
my $sourcedir = ".";
mkdir $builddir;
sub generate{
    my $filename = $_[0];
    open(my $src_file, "<", $filename) or die "Unable to open source file";
    if(<$src_file> !~ /<!DOCTYPE HTML>/i){
        print "Skipping $filename; missing doctype\n";
        return;
    }
    seek $src_file, 0, 0; # return src_file beack to begining
    open(my $dst_file, ">", catfile($builddir, $filename));
    select $dst_file;
    while(<$src_file>){
        if(/([ \t]*)(.*)<!--include ([^>]*)-->(.*)/){
            my $whitespace = $1;
            my $before = $2;
            my $include_name = $3;
            my $after = $4;

            print $whitespace, $before;
            open(my $template_file, "<", $include_name) or die "Unable to open template file ", $include_name;
            print scalar <$template_file>;
            while(<$template_file>){
                chomp if eof;
                print $whitespace;
                print;
            }
            print $after, "\n";
            close($template_file);
        }else{
            print;
        }
    }
    select STDOUT;
    close($src_file);
    close($dst_file);
};
my $what=opendir(my $sourcedir_handle, $sourcedir);
print $sourcedir, "\n";
while(readdir($sourcedir_handle)){
    if(/build$/){
        #Skip file
        print "Skipping file: ", $_, "\n";
    }elsif(/.*\.html$/){
        print "processing html: ", $_, "\n";
        generate $_;
    }elsif(/.*\.(css|png|svg|ico)$/){
        print "copying $1: ", $_, "\n";
        copy($_, catfile($builddir, $_));
    }elsif(/(\.nojekyll|CNAME)$/){
        print "copying $1: ", $_, "\n";
        copy($_, catfile($builddir, $_));
    }else{
        print "Ignoring file: ", $_, "\n";
    }
}
closedir($sourcedir_handle);
