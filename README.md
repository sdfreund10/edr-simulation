# EDR Simulation
This library was built to simulate various system activity for Endpoint Detection and Response (EDR) agent validation. It currently simulates three basic activities 
- File creation, modification, and deletion
- Running an executable file
- Downloading data from a remote source

● Start a process, given a path to an executable file and the desired (optional)
command-line arguments
● Create a file of a specified type at a specified location
● Modify a file
● Delete a file
● Establish a network connection and transmit data

## Requirements
- MacOS or Linux
- ruby 2.7.1 or later
  - Might work on earlier versions, but this was the earliest I tested against

## Usage
### Install
```
# pull repository
git clone git@github.com:sdfreund10/edr-simulation.git

# install gems
bundle install
```

### Basic usage
This libary is primarily intended to be used via a CLI.
```
./bin/simulate
# > Starting Simulation #1010
# > Simulation #1010 complete
# > View results in logs/edr_simulation_run_1010.json
```

Running the executable with no arguments performs all operations in the `tmp` directory and outputs logs to `logs` directory

#### File operation options
```
touch m.txt d.txt
./bin/simulate --modify_file_location m.txt --delete_file_location d.txt --create_file_location spec/tmp --create_file_extension json
```

- `--modify_file_location`
  - specifies an existing file to test mofication against
  - by default will create and modify a new file in the `tmp` directory

- `--delete_file_location`
  - specifies an existing file to test deletion against. THIS WILL DELETE THE PROVIDED FILE
  - by default will create and delete a new file in the `tmp` directory

- `--create_file_location`
  - specifies directory in which to create files
  - default: `tmp`

- `--create_file_extension`
  - specifies what extension to use when creating file
  - default: `txt`

#### Executable options

```
./bin/simulate --executable touch --executable_args text.txt,test.txt
```
- `--executable`
  - specifies what executable to run
  - default: `echo`
- `--executable_args`
  - specifies arguments to executable. only required when used with `--executable` option
  - default: `''`


## Docker example
Used primarily for testing against Linux distribution
```
# build container
docker build -t edr-simulation-ubuntu .
# run simulation
docker run edr-simulation-ubuntu ./bin/simulate
# print results
docker run edr-simulation-ubuntu cat <see logfile location from run output>
```
