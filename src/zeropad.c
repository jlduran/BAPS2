#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(int argc, char *argv[]) {
    FILE *fin, *fout;
    char *buf;
    int  n;
    int  blocksize;
   
    if (argc != 4) {
	printf("usage: %s InputFile PaddedFile BlockSize\n", argv[0]);
	exit(1);
    }
	
    fin = fopen(argv[1],"rb");
    if (fin == NULL) {
	printf("Error opening %s\n", argv[1]);
	exit(1);
    }
    
    fout = fopen(argv[2],"wb");
    if (fout == NULL) {
	printf("Error opening %s\n", argv[2]);
	exit(1);
    }

    blocksize = strtol(argv[3], NULL, 0);
    if (blocksize < 0) {
	printf("Error in blocksize\n");
	exit(1);
    }
    printf("blocksize = %d (0x%0x)\n", blocksize, blocksize);

    buf = (char *)malloc(blocksize);
    if (buf == NULL) {
	printf("Error in blocksize\n");
	exit(1);
    }
    memset(buf, 0, blocksize);

    while((n = fread(buf, sizeof(char), blocksize, fin))) {
	fwrite(buf, sizeof(char), blocksize, fout);
    }

    free(buf);
    fclose(fin);
    fclose(fout);
    
    return 0;
}
