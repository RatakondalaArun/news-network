ROOT=$PWD

echo "Removing log.txt file"
rm log.txt
rm newsnet.tar.gz

echo -e "\n\n"
echo "Removing Docker containers"

# stop docker containers
docker stop $(docker ps -a -q)
# remove docker containers
docker rm $(docker ps -a -q)

echo -e "\n\n"
echo "Removing network Files"
# navigate to channel folder
cd ./artifacts/channel
# remove crypto-config folder
rm -r crypto-config
# remove transaction files
rm *.tx
# remove genesis block
rm genesis.block
