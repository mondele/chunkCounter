unit tStudio;

interface
    // tStudio unit will have the following interfaces:
    //
    //  1. project class
    //      1. language code
    //      2. book code
    //      3. project type (ulb or reg (or udb (rarely)) or tn/tq (even more rarely))
    //      4. closed chunks list or something
    //      5. present chunk files
    //      6. list of sources

uses
    // unit will need access to the file system, and be able to parse and write json. Access
    //  to git would probably also be useful (verify that a project git status is correct)

implementation
    // this is where we'll actually implement the tstudio class

begin

end.