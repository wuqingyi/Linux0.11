#include <stdint.h>
#include <sys/types.h> /* unistd.h needs this */
#include <sys/stat.h>
#include <linux/fs.h>
#include <unistd.h> /* contains read/write */
#include <fcntl.h>
#include <stdio.h>

/* Type for a 16-bit quantity.  */
typedef uint16_t Elf32_Half;

/* Types for signed and unsigned 32-bit quantities.  */
typedef uint32_t Elf32_Word;
typedef int32_t Elf32_Sword;

/* Types for signed and unsigned 64-bit quantities.  */
typedef uint64_t Elf32_Xword;
typedef int64_t Elf32_Sxword;

/* Type of addresses.  */
typedef uint32_t Elf32_Addr;

/* Type of file offsets.  */
typedef uint32_t Elf32_Off;

/* Type for section indices, which are 16-bit quantities.  */
typedef uint16_t Elf32_Section;

/* Type for version symbol information.  */
typedef Elf32_Half Elf32_Versym;

/* The ELF file header.  This appears at the start of every ELF file.  */

#define EI_NIDENT (16)

typedef struct
{
    unsigned char e_ident[EI_NIDENT]; /* Magic number and other info */
    Elf32_Half e_type;                /* Object file type */
    Elf32_Half e_machine;             /* Architecture */
    Elf32_Word e_version;             /* Object file version */
    Elf32_Addr e_entry;               /* Entry point virtual address */
    Elf32_Off e_phoff;                /* Program header table file offset */
    Elf32_Off e_shoff;                /* Section header table file offset */
    Elf32_Word e_flags;               /* Processor-specific flags */
    Elf32_Half e_ehsize;              /* ELF header size in bytes */
    Elf32_Half e_phentsize;           /* Program header table entry size */
    Elf32_Half e_phnum;               /* Program header table entry count */
    Elf32_Half e_shentsize;           /* Section header table entry size */
    Elf32_Half e_shnum;               /* Section header table entry count */
    Elf32_Half e_shstrndx;            /* Section header string table index */
} Elf32_Ehdr;

/* Program segment header.  */

typedef struct
{
    Elf32_Word p_type;   /* Segment type */
    Elf32_Off p_offset;  /* Segment file offset */
    Elf32_Addr p_vaddr;  /* Segment virtual address */
    Elf32_Addr p_paddr;  /* Segment physical address */
    Elf32_Word p_filesz; /* Segment size in file */
    Elf32_Word p_memsz;  /* Segment size in memory */
    Elf32_Word p_flags;  /* Segment flags */
    Elf32_Word p_align;  /* Segment alignment */
} Elf32_Phdr;

char hbuf[1024];
char buf[1024];

int main(void)
{
    int id = open("./system.elf", O_RDONLY, 0);
    if (id < 0)
    {
        printf("open");
        return -1;
    }
    if (read(id, hbuf, sizeof(Elf32_Ehdr)) != sizeof(Elf32_Ehdr))
    {
        printf("read");
        return -1;
    }
    Elf32_Ehdr *ehdr = (Elf32_Ehdr *)(void *)hbuf;
    long offset = ehdr->e_phoff;
    int entry_size = ehdr->e_phentsize;
    int entry_nr = ehdr->e_phnum;
    lseek(id, ehdr->e_phoff, SEEK_SET);
    if (read(id, hbuf, entry_size * entry_nr) != entry_size * entry_nr)
    {
        printf("program entry");
        return -1;
    }
    Elf32_Phdr *phdr = (Elf32_Phdr *)(void *)hbuf;
    int i = 0;
    int fd = open("kernel.bin", O_CREAT | O_RDWR, S_IRUSR | S_IWUSR);
    for (; i < entry_nr; i++, phdr++)
    {
        int poff = phdr->p_offset;
        int voff = phdr->p_vaddr;
        int psize = phdr->p_filesz;
        int msize = phdr->p_memsz;
        int readsz = 0;
        while (readsz < psize)
        {
            lseek(id, poff + readsz, SEEK_SET);
            lseek(fd, voff + readsz, SEEK_SET);
            if (psize - readsz <= 1024)
            {
                read(id, buf, psize - readsz);
                write(fd, buf, psize - readsz);
                break;
            }
            read(id, buf, 1024);
            write(fd, buf, 1024);
            readsz += 1024;
        }
        if (msize > psize)
        {
            readsz = psize;
            for (int j = 0; j < 1024; j++)
            {
                buf[j] = 0;
            }
            while (readsz < msize)
            {
                lseek(fd, voff + readsz, SEEK_SET);
                if (msize - readsz <= 1024)
                {
                    write(fd, buf, msize - readsz);
                    break;
                }
                write(fd, buf, 1024);
                readsz += 1024;
            }
        }
    }
    close(fd);
    close(id);
    return 0;
}