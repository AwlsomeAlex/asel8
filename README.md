# Apple Silicon-Compatible kErneL foR el8 (ascelr8)

This project is an attempt to get EL8 working on Apple Silicon Macs (through virtualization). This differs from the Asahi Linux project as it isn't designed to run on bare metal. I plan on this being an ISO I can throw into Parallels or UTM and boot whenever I please. 

The scope of the projecy is to provide the tools necessary in building a patched kernel and a patched installer ISO. If all goes well, I might even host a repository on my website and automate the build.

## Part I: Modified el8 Kernel

The primary reason el8 systems can't run on Apple Silicon is because they're compiled with 64KB paging. Apple Silicon only supports 4KB and 16KB paging. el9 has 4KB paging by default (probably unrelated), so el9 can run fine in VMs. There's even a couple of projects trying to get bare metal working as well!

Oracle provides a special kernel with Oracle Linux (UEK) that, since Oracle Linux 8.7, can run on Apple Silicon Macs. This is because they switched it to 4KB as well. While that's a fine solution, they also include a lot of tweaks that take it further away from the source material.

The idea is to build el8's kernel in a el8 container and then modify an installer ISO to use the patched kernel RPM. For now it's based on Rocky Linux 8, but theoretically it'll work on Almalinux as well with minimal changes.

I won't be targeting or using anything Red Hat nor Oracle for legal reasons. I'm also refraining from using the UBIs since they don't include the build-deps required to build their kernel RPM. Nice one guys.

If this ends up working well I'll get in touch with the Rocky or Alma peeps and see if this is something they'd be interested in being a SIG.

### Building the ascelr8 Docker image

`docker build -t awlsome/ascelr8:latest .`

### Running the ascelr8 Docker image

`docker run --privileged -it --rm -v rpms:/opt/rpms awlsome/ascelr8:latest`

### Building the modified kernel

`./ascelr8.sh -b`

*More to come :)*

## License
Awlsome License v1, All Rights Reserved.

## Contributors
* AwlsomeAlex (Alexander Barris)
