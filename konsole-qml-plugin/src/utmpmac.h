#if defined (__APPLE__)
# include <utmp.h>

struct utmp *getutent();
struct utmp *getutid( struct utmp * );
struct utmp *getutline( struct utmp * );
void pututline( struct utmp * );
void setutent();
void endutent();
void utmpname( char * );
void updwtmp(const char *wtmp_file, const struct utmp *lutmp);

#endif
