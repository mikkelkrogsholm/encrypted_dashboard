for userdetails in `cat users.csv`
do
        # Setup user details
        USER=`echo $userdetails | cut -f 1 -d ,`
	 	PASSWD=`echo $userdetails | cut -f 2 -d ,`
        
        # add user without using skel template
        useradd -m $USER 

        # make homefolder
		mkdir /home/$USER 

		# own the home folder to correct user
		chown -R $USER /home/$USER 

		# add the user to the staff group
		usermod -a -G staff $USER 

		## Add a password to user
		echo "$USER:$PASSWD" | chpasswd
done




