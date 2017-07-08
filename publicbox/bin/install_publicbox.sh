#!/bin/sh
## PublicBox installer script  
##  created by Matthias Strubel   (c)2011-2014 GPL-3
##

create_content_folder(){

   echo "Creating 'content' folder on USB stick and move over stuff"
   mkdir -p $WWW_CONTENT
   cp -r     $PUBLICBOX_FOLDER/www_content/*   $WWW_CONTENT

   [ ! -L $PUBLICBOX_FOLDER/www/content  ] && \
		ln -s $WWW_CONTENT  $WWW_FOLDER/content
   [ ! -e $WWW_FOLDER/favicon.ico ] && \
		ln -s $WWW_CONTENT/favicon.ico $WWW_FOLDER

   chown $LIGHTTPD_USER:$LIGHTTPD_GROUP  $WWW_CONTENT -R
   chmod  u+rw $WWW_CONTENT
   return 0
}

# Load configfile

if [ -z  $1 ] || [ -z $2 ]; then 
  echo "Usage install_publicbox my_config <part>"
  echo "   Parts: "
  echo "       part2          : sets Permissions and links correctly"
  echo "       imageboard     : configures kareha imageboard with Basic configuration"
  echo "                        should be installed in <Publicbox-Folder>/share/board"
  echo "       pyForum        : Simple PythonForum"
  echo "       station_cnt        : Adds Statio counter to your Box - crontab entry"
  echo "       flush_dns_reg      : Installs crontask to flush dnsmasq regulary"
  echo "       hostname  'name'   : Exchanges the Hostname displayed in browser"
  exit 1
fi


if [ !  -f $1 ] ; then 
  echo "Config-File $1 not found..." 
  exit 1 
fi

#Load config
PUBLICBOX_CONFIG=$1
. $1 

if [ $2 = 'pyForum' ] ; then
    cp -v $PUBLICBOX_FOLDER/src/forest.py  $WWW_FOLDER/cgi-bin
    cp -v $PUBLICBOX_FOLDER/src/forest.css $WWW_FOLDER/content/css
    mkdir -p $PUBLICBOX_FOLDER/forumspace
    chmod a+rw -R  $PUBLICBOX_FOLDER/forumspace 2> /dev/null
    chown $LIGHTTPD_USER:$LIGHTTPD_GROUP  $WWW_FOLDER/cgi-bin/forest.py
    chown $LIGHTTPD_USER:$LIGHTTPD_GROUP  $WWW_FOLDER/content/forest.css  2> /dev/null
    echo "Copied the files. Recheck your PublicBox now. "
fi



if [ $2 = 'part2' ] ; then
   echo "Starting initialize PublicBox Part2.."
#Create directories 
#   mkdir -p $PUBLICBOX_FOLDER/share/Shared
   mkdir -p $UPLOADFOLDER
   mkdir -p $PUBLICBOX_FOLDER/share/board
   mkdir -p $PUBLICBOX_FOLDER/share/tmp
   mkdir -p $PUBLICBOX_FOLDER/tmp

   #Distribute the Directory Listing files
   $PUBLICBOX_FOLDER/bin/distribute_files.sh $SHARE_FOLDER/Shared true
   #Set permissions
   chown $LIGHTTPD_USER:$LIGHTTPD_GROUP  $PUBLICBOX_FOLDER/share -R
   chmod  u+rw $PUBLICBOX_FOLDER/share
   chown $LIGHTTPD_USER:$LIGHTTPD_GROUP  $PUBLICBOX_FOLDER/www -R
   chmod u+x $PUBLICBOX_FOLDER/www/cgi-bin/* 
   chown $LIGHTTPD_USER:$LIGHTTPD_GROUP  $PUBLICBOX_FOLDER/tmp
   chown $LIGHTTPD_USER:$LIGHTTPD_GROUP  $PUBLICBOX_FOLDER/tmp -R


#Install a small script, that the link on the main page still works
   if  [ !  -f $PUBLICBOX_FOLDER/share/board/kareha.pl ] ; then  
      cp $PUBLICBOX_FOLDER/src/kareha.pl $PUBLICBOX_FOLDER/share/board
   fi
  
   [ ! -L $PUBLICBOX_FOLDER/www/board  ] && ln -s $PUBLICBOX_FOLDER/share/board $PUBLICBOX_FOLDER/www/board
   [ ! -L $PUBLICBOX_FOLDER/www/Shared ] && ln -s $UPLOADFOLDER  $PUBLICBOX_FOLDER/www/Shared
   [ ! -L $PUBLICBOX_FOLDER/www/content  ] && \
       ln -s $WWW_CONTENT  $WWW_FOLDER/content

fi 

#Install the image-board
if [ $2 = 'imageboard' ] ; then
   
    if [ -e  $PUBLICBOX_FOLDER/share/board/init_done ] ; then
       echo "$PUBLICBOX_FOLDER/share/board/init_done file Found in Kareha folder. Won't reinstall board."
       exit 0;
    fi

    
    cd $PUBLICBOX_FOLDER/tmp
    KAREHA_RELEASE=kareha_3.1.4.zip
    if [ ! -e $PUBLICBOX_FOLDER/tmp/$KAREHA_RELEASE ] ; then
	echo "  Wgetting kareha-zip file "
    	wget http://wakaba.c3.cx/releases/$KAREHA_RELEASE
	if [ "$?" != "0" ] ; then
       		echo "wget kareha failed.. you can place the current file your to  $PUBLICBOX_FOLDER/tmp "
	 fi
    fi

    if [ -e  $PUBLICBOX_FOLDER/tmp/$KAREHA_RELEASE ] ; then
       echo "Kareha Zip found..."
    else 
       echo "No Zip found, abort "
       exit 255
    fi
    
    unzip $KAREHA_RELEASE
    mv kareha/* $PUBLICBOX_FOLDER/share/board 
    rm  -rf $PUBLICBOX_FOLDER/tmp/kareha* 
    
    cd  $PUBLICBOX_FOLDER/share/board  
    cp -R  mode_image/* ./   
    cp  $PUBLICBOX_FOLDER/src/kareha_img_config.pl $PUBLICBOX_FOLDER/share/board/config.pl 
    cp  $PUBLICBOX_FOLDER/src/no_forum.html  $PUBLICBOX_FOLDER/share/board/index.htm
    chown -R $LIGHTTPD_USER:$LIGHTTPD_GROUP  $PUBLICBOX_FOLDER/share/board   
    #Install filetype thumbnails
    mv $PUBLICBOX_FOLDER/share/board/extras/icons  $PUBLICBOX_FOLDER/share/board/ 

    echo "Errors in chown occurs if you are using vfat on the USB stick"
    echo "   . don't Panic!"
    echo "Generating index page"
    cd /tmp
    wget -q http://127.0.0.1/board/kareha.pl 
    echo "finished!"
    echo "Now Edit your kareha settings file to change your ADMIN_PASS and SECRET : "
    echo "  # vi $PUBLICBOX_FOLDER/www/board/config.pl "

    touch  $PUBLICBOX_FOLDER/share/board/init_done
fi

if [ $2 = "station_cnt" ] ; then
    #we want to append the crontab, not overwrite
    crontab -l   >  $PUBLICBOX_FOLDER/tmp/crontab 2> /dev/null
    echo "#--- Crontab for PublicBox-Station-Cnt" >>  $PUBLICBOX_FOLDER/tmp/crontab
    echo " */2 * * * *    $PUBLICBOX_FOLDER/bin/station_cnt.sh >  $WWW_FOLDER/station_cnt.txt "  >> $PUBLICBOX_FOLDER/tmp/crontab
    crontab $PUBLICBOX_FOLDER/tmp/crontab
    [ "$?" != "0" ] && echo "an error occured" && exit 254
    $PUBLICBOX_FOLDER/bin/station_cnt.sh >  $WWW_FOLDER/station_cnt.txt
    echo "installed, now every 2 minutes your station count is refreshed"
fi

if [ $2 = "flush_dns_reg" ] ; then
    crontab -l   >  $PUBLICBOX_FOLDER/tmp/crontab 2> /dev/null
    echo "#--- Crontab for dnsmasq flush" >>  $PUBLICBOX_FOLDER/tmp/crontab
    echo " */2 * * * *    $PUBLICBOX_FOLDER/bin/flush_dnsmasq.sh >  $PUBLICBOX_FOLDER/tmp/dnsmasq_flush.log "  >> $PUBLICBOX_FOLDER/tmp/crontab
    crontab $PUBLICBOX_FOLDER/tmp/crontab
    [ "$?" != "0" ] && echo "an error occured" && exit 254
    echo "Installed crontab for flushing dnsmasq requlary"
fi

set_hostname() {
	local name=$1 ; shift;

	sed  "s|#####HOST#####|$name|g"  $PUBLICBOX_FOLDER/src/redirect.html.schema >  $WWW_FOLDER/redirect.html
        sed "s|HOST=\"$HOST\"|HOST=\"$name\"|" -i  $PUBLICBOX_CONFIG
}

if [ $2 = "hostname" ] ; then
	echo "Switching hostname to $3"
	set_hostname "$3"
	echo "..done"
fi

if [ $2 = "content" ] ; then
	create_content_folder
fi
