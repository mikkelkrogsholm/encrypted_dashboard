# Set umask value
echo "server-set-umask=false" >> /etc/rstudio/rserver.conf

# Loop that runs through the users in the user.csv file and adds them to the system.
for userdetails in `cat users.csv`
do
        # Setup user details
        USER=`echo $userdetails | cut -f 1 -d ,`
        PASSWD=`echo $userdetails | cut -f 2 -d ,`

        # add user without using skel template
        useradd -m $USER

        # own the home folder to correct user
        chown -R $USER /home/$USER

        # add home folder to staff group
        chgrp -R staff /home/$USER
        chmod -R 2775 /home/$USER
        echo "Sys.umask(mode=002)" >> /home/$USER/.Rprofile

        # add the user to the staff group
        usermod -a -G staff $USER

        # Add a password to user
        echo "$USER:$PASSWD" | chpasswd
done
