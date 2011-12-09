asdasdasdads#include <stdio.h>

//TEXTY_EXECUTE gcc -o {MYDIR}/{MYSELF_BASENAME_NOEXT} {MYSELF} && gdb {MYDIR}/{MYSELF_BASENAME_NOEXT} {NOTIMEOUT} 
int main(int ac, char **av) {
	int t;
	printf("texty rocks - %s\n",av[0]);
	for(;;) {
		t = time(NULL);
		printf("yee: %d\n",t);
		fprintf(stderr,"stderr: %d\n",t);
		sleep(1);
	}
}
{{}}}}}}}}}}}}}}}}}}}}}
