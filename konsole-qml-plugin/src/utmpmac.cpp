#if defined (__APPLE__)
#include "utmpmac.h"

typedef enum { F=0, T=1 } boolean;

static int utmpfd = -1;
static char utmpath[PATH_MAX+1] = _PATH_UTMP;
static boolean readonly = F;
static struct utmp utmp;


struct utmp *getutent();
struct utmp *getutid( struct utmp * );
struct utmp *getutline( struct utmp * );
void pututline( struct utmp * );
void setutent();
void endutent();
void utmpname( char * );


 static
 struct utmp *
_getutent( struct utmp *utmp )
{
  if ( utmpfd == -1 )
    {
      if ( (utmpfd = open(utmpath,O_RDWR)) == -1 )
        {
          if ( (utmpfd = open(utmpath,O_RDONLY)) == -1 )
            return NULL;
          else
            readonly = T;
        }
      else
        readonly = F;
    }

  if ( read(utmpfd,utmp,sizeof(struct utmp)) == sizeof(struct utmp) )
    return utmp;

  return NULL;
}


 struct utmp *
getutent()
{
  return _getutent( &utmp );
}


 struct utmp *
getutid( struct utmp *id )
{
  struct utmp *up;

  if ( strncmp(id->ut_name,utmp.ut_name,UT_NAMESIZE) == 0 )
    return &utmp;

  while( (up = getutent()) != NULL )
    {
      if ( strncmp(id->ut_name,up->ut_name,UT_NAMESIZE) == 0 )
        return up;
    }

  return NULL;
}


 struct utmp *
getutline( struct utmp *line )
{
  struct utmp *up;

  if ( strncmp(line->ut_line,utmp.ut_line,UT_LINESIZE) == 0 )
    return &utmp;

  while( (up = getutent()) != NULL )
    {
      if ( strncmp(line->ut_line,up->ut_line,UT_LINESIZE) == 0 )
        return up;
    }

  return NULL;
}


 void
pututline( struct utmp *up )
{
  struct utmp temp;
  struct stat buf;

  /* Note that UP might be equal to &UTMP */

  if ( strncmp(up->ut_name,utmp.ut_name,UT_NAMESIZE) == 0 )
    /* File already at correct position */
    {
      if ( ! readonly )
        {
          lseek( utmpfd, -(off_t)sizeof(struct utmp), SEEK_CUR );
          write( utmpfd, up, sizeof(struct utmp) );
        }

      utmp = *up;
    }
  else
    /* File is not at the correct postion; read forward, but do not destroy 
UTMP */
    {
      while( _getutent(&temp) != NULL )
        {
          if ( strncmp(up->ut_name,temp.ut_name,UT_NAMESIZE) == 0 )
            /* File is now at the correct position */
            {
              if ( ! readonly )
                {
                  lseek( utmpfd, -(off_t)sizeof(struct utmp), SEEK_CUR );
                  write( utmpfd, up, sizeof(struct utmp) );
                }

              utmp = *up;
              return;
            }
        }

      /* File is now at EOF */
      if ( ! readonly )
        {
          if ( fstat(utmpfd,&buf) == 0 && lseek(utmpfd,0,SEEK_END) != -1 )
            {
              if ( write(utmpfd,up,sizeof(struct utmp)) != sizeof(struct utmp) 
)
                ftruncate( utmpfd, buf.st_size );
            }
        }

      utmp = *up;
    }
}


 void
setutent()
{
  if ( utmpfd != -1 )
    lseek( utmpfd, 0, SEEK_SET );
}


 void
endutent()
{
  if ( utmpfd != -1 )
    {
      close( utmpfd );
      utmpfd = -1;

      memset( &utmp, 0, sizeof(struct utmp) );
    }
}


 void
utmpname( char *file )
{
  endutent();

  strncpy( utmpath, file, PATH_MAX );
}
// https://dev.mobileread.com/svn/iliados/upstream/tinylogin-1.4/libbb/libc5.c
void updwtmp(const char *wtmp_file, const struct utmp *lutmp)
{
        int fd;

        fd = open(wtmp_file, O_APPEND | O_WRONLY, 0);
        if (fd >= 0) {
                if (lockf(fd, F_LOCK, 0)==0) {
                        write(fd, (const char *) lutmp, sizeof(struct utmp));
                        lockf(fd, F_ULOCK, 0);
                        close(fd);
                }
        }
}

#endif
