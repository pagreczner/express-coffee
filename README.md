Node-Expresso is a fork of the popular coffee-script project by @jashkenas.

It provides a coffee-script console that is meant to be run from within
your Express project file structure.  It auto requires all modules needed
for that express application. And it also finds all inline documentation for
the methods.

Installing:
```
> npm install -g node-expresso
```

Running the command line:
```
> cd ~/myExpressProjectRoute
> expresso
```

Expresso will now load all the required files and for any which it can not load
it will print them out.  From here you have a coffee console at your disposal.

```
expressCoffee> console.log "Hello World"
```

For modules which it has auto required, Expresso attempts to find inline documentation
for them and you can use a built-in 'man' command to see it.

```
expressCoffee> man userRepo.createNewUser
Usage:
userRep.createNewUser (first, last, age)
This method creates a new user and stores them in the database.  It returns back
the user id of the newly created user.
Inputs:
   String: first - the first name
   String: last - the last name
   age: int - the users age
```

Expresso is a continuing work in progress, so not all node Express applications
may work 100% with the current functionality.  And, it assumes you have a /server
folder in your Express project.

---------------

For more information on CoffeeScript, check out: http://coffeescript.org/

