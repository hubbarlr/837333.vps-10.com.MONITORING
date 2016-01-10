#! /usr/bin/python

import sys

def process(line):
	break_line=line.split('to=<')
	break_domain=break_line[1].split('>')
	print break_domain[0]

for line in sys.stdin:
	process(line)
