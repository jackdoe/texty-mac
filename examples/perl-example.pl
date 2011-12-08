#!/usr/bin/perl

#TEXTY_EXECUTE perl {MYSELF} {NOTIMEOUT}
while (<STDIN>) {
	last if /^quit/;
	print system($_);
}
