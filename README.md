## githubDetect

use github api search [ `repos followings gists` ] base on listed users.

use github api search keyword in github [ `code commits issues labels repositories topics users` ] 

### useage

`./githubDetect.sh -h`
to get help info.


encrypte "github auth" and "sender email password" with salt value to two file > [ `GITHUBAUTHF` ], [ `SENDERPWDF` ]

in order to protect you pwd, must input saltvalue with [ `-a` ], 
`./githubDetect.sh -a "saltvalue"`


need install jq, curl, sendemail, openssl

`sudo apt update && sudo apt install -y sendemail curl jq openssl`


if wanna search following users' [ `public repos` ] and [ `gists` ], must put [ `-f` ] at the end !

for example,CC to example@domain.com,and search following users:

`./githubDetect.sh -a Example@123# -c example@domain.com.cn -f`



### instruction

need those files: separated with space or return.

or use [ `-h` ] options to send value!


[ `WKUNLIST` ]: working username list, will search public [ `CKTPLIST` ], if exist, send email !

[ `PSUNLIST` ]: personal account list, will search keyword in public [ `repos gists` ], if exist, send email !

[ `KWDLIST`  ]: key word list, can search mulitple word at the same time,eg. cienet+password=

[ `SCKWDLIST` ]: keyword search in all github, can search mulitple word at the same time,eg. cienet+password=

[ `SCTPLIST` ]: search type in all github, can be [ `code commits issues labels repositories topics users` ].

[ `CKTPLIST` ]: search type in users, can be [ `repos gists following` ].

[ `SENDERPWDF` ]: encrypted sender email password.

[ `GITHUBAUTHF` ]: encrypted github auth code.

[ `TOEMAILLIST` ]: Recipient list.

[ `CCEMAILLIST` ]: CC Recipient list.

[ `SMTPADDR` ]: smtp address.

[ `SENDEREMAIL` ]: sender email.


password加密方法:

这次Example@123#是盐值,使用时可以自己设置,盐值保管好,不可写入到文件。最好在执行命令前添加空格,这样命令不会保存到history中。

`#   ./githubDetect.sh`

使用时,先用以下加密命令分别将github auth密码和发件邮箱密码加密传入[ `GITHUBAUTHF` ]和[ `SENDERPWDF` ]中，
脚本会优先使用[ `-e` ]和[ `-g` ]参数传入的值,如果不输入参数,则读取这两个文件并解密获得密码。


加密：
`echo "password" | openssl enc -aes-256-cbc -md sha512 -a -pbkdf2 -iter 100000 -salt -pass pass:Example@123# > GITHUBAUTHF`

`echo "password" | openssl enc -aes-256-cbc -md sha512 -a -pbkdf2 -iter 100000 -salt -pass pass:Example@123# > SENDERPWDF`
