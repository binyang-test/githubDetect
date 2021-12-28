#!/bin/bash
# Author: bin.yang
# Email: bin.yang@cienet.com.cn
# Created Date: 15 Dec 2021

set -ue

#working account list
WKUNLIST=''
#personal account
PSUNLIST=''
#key word list search in users
KWDLIST=''
#keyword search in all github
SCKWDLIST=''
#search type in all github
SCTPLIST='code commits issues repositories topics users'
#search type in users
CKTPLIST='repos gists following'
#salt value
SALTVALUE=''
#githubauth encrypted auth code
GITHUBAUTHF=''
#sender encrypted pwd
SENDERPWDF=''
#whether search following users, default is No
ISSCF=0
PERPAGE=50

# email settings
TODAY=`date +%y-%m-%d`
EMAILSUBJECT="Github Scan Report $TODAY ,Found illegal resources in github, Please inform related to delete them!"
TOEMAILLIST=''
CCEMAILLIST=''
SMTPADDR=''
SENDEREMAIL=''
ALLNEEDCKVAR='WKUNLIST PSUNLIST KWDLIST SCKWDLIST SCTPLIST CKTPLIST SENDERPWDF GITHUBAUTHF TOEMAILLIST CCEMAILLIST SMTPADDR SENDEREMAIL'

function usage(){ echo "Usage: $0 [-h] [-s saltValue] -- search keyword in github, must input saltValue with -a !

input options or write them in files

need files:

WKUNLIST -- working accout, won't search keyword.

PSUNLIST -- personal account, will search keyword in listed account.

KWDLIST -- keyword search in [ PSUNLIST ] users, separated with space or return, if wanna search multiple keyword at one time, connect the key word with [ + ], such as [ cienet+password ].

SCKWDLIST -- keyword search in all github, separated with space or return, if wanna search multiple keyword at one time, connect the key word with [ + ], such as [ cienet+password ].

SCTPLIST -- search type in all github, can be [ repositories code commits issues topics users ], separated with space or return, default is all.

CKTPLIST -- search type in listed user, can be [ repos gists following ], default is all.

SALTVALUE -- salt value to encrypt and decrypt sender email password and github auth code.

SENDERPWDF -- sender email password, use openssl to encrypt, as follows:
    echo "Password" | openssl enc -aes-256-cbc -md sha512 -a -pbkdf2 -iter 100000 \
    -salt -pass pass:saltValue > SENDERPWDF

GITHUBAUTHF -- github auth code encrypted with saltValue to GITHUBAUTHF, as above [ SENDERPWDF ].

TOEMAILLIST -- receiver

CCEMAILLIST -- CC receiver

SMTPADDR -- smtp address

SENDEREMAIL -- sender email(only accept one)

where:
    -h  1.show this help text.
    -w  2.add working account username list.
    -p  3.add personal account username list.
    -k  4.add keyword search in personal acccount.
    -s  5.add keyword search in all github.
    -a  6.input saltValue to decode github auth and sender email password.
    -e  7.input sender email password encrypted with salt value.
    -g  8.input github auth code encrypted with salt value.
    -t  9.add receiver email.
    -c  10.add CC receiver email.
    -m  11.smtp address, default is smtp.263.net.
    -n  12.sender email.
    -f  13.search personal users' following users repos, gists. default is No.

    must input saltValue with -a !!! "    1>&2; exit 1;
}

while getopts ":hw:p:k:s:a:e:g:t:c:m:n:f" option; do
  case "$option" in
    h)  usage
        ;;
    w)  echo "$OPTARG" >> WKUNLIST
        echo "WKUNLIST added $OPTARG"
        ;;
    p)  echo "$OPTARG" >> PSUNLIST
        echo "PSUNLIST added $OPTARG"
        ;;
    k)  echo "$OPTARG" >> KWDLIST
        echo "KWDLIST added $OPTARG"
        ;;
    s)  echo "$OPTARG" >> SCKWDLIST
        echo "SCKWDLIST added $OPTARG"
        ;;
    a)  SALTVALUE="$OPTARG"
        echo "saltValue is $SALTVALUE"
        ;;
    e)  SENDERPWDF="$OPTARG"
        ALLNEEDCKVAR=`echo $ALLNEEDCKVAR | sed 's/SENDERPWDF//'`
        echo "smtp encrypted pwd is $SENDERPWDF, ignore the file SENDERPWDF"
        ;;
    g)  GITHUBAUTHF="$OPTARG"
        ALLNEEDCKVAR=`echo $ALLNEEDCKVAR | sed 's/GITHUBAUTHF//'`
        echo "github encrypted auth is $GITHUBAUTHF, ignore the file GITHUBAUTHF"
        ;;
    t)  echo "$OPTARG" >> TOEMAILLIST
        echo "receiver added $OPTARG"
        ;;
    c)  echo "$OPTARG" >> CCEMAILLIST
        echo "CC receiver added $OPTARG"
        ;;
    m)  SMTPADDR="$OPTARG"
        ALLNEEDCKVAR=`echo $ALLNEEDCKVAR | sed 's/SMTPADDR//'`
        echo "smtp address is $OPTARG, ignore the file SMTPADDR"
        ;;
    n)  SENDEREMAIL="$OPTARG"
        ALLNEEDCKVAR=`echo $ALLNEEDCKVAR | sed 's/SENDEREMAIL//'`
        echo "sender email is $OPTARG, ignore the file SENDEREMAIL"
        ;;
    f)  ISSCF=1
        echo "will search all following users of psunlist"
        ;;
    :)  printf "missing argument for -%s\n" "$OPTARG" >&2
        usage
        ;;
   \?)  printf "illegal option: -%s\n" "$OPTARG" >&2
        usage
        ;;
  esac
done

#checked username list
CKDUNLIST=''
#following users list
ALLFOLLOWING=''
#block url
BURL=''
#user repo
GHURL='https://api.github.com'
BASEURL="$GHURL/users"
#jq
JQ2A="to_entries|map(\"\(.key)=\(.value|tostring)\")|.[]"
#0
LIMIT=0
#check these type
USERGITHUBTYPE='public_repos public_gists following'
#whether send email
isSend=$LIMIT
LISTCK='echo " [ $itemName ] list is empty !
Please input [ $itemName ] separated with space and return to run:
or write into the [ $itemName ] File with this script in the same dir, then run again!
or ctrl + c to stop this shit script O_O!"'
GITHUBAUTH=''
SENDERPWD=''


function CheckVar() {
    if [[ -z $SALTVALUE ]]; then usage; fi
    # if var in ALLNEEDCKVAR is empty, ask input once
    # ALLNEEDCKVAR='WKUNLIST PSUNLIST KWDLIST SCKWDLIST SCTPLIST CKTPLIST SENDERPWDF GITHUBAUTHF TOEMAILLIST CCEMAILLIST SMTPADDR SENDEREMAIL'
    for ndCkVar in $ALLNEEDCKVAR; do
        if [[ -f "$ndCkVar" ]]; then
        eval "$ndCkVar=\"$(eval echo $`echo $ndCkVar`) `cat $ndCkVar`\"";
        fi
        eval echo "$ndCkVar  is  $`echo $ndCkVar`";
        ckVar=$(eval echo $ndCkVar)
        if [[ -z $(eval echo $`echo $ndCkVar`) ]]; then
            itemName=$(eval echo $ndCkVar)
            eval "$LISTCK"
            read varLine
            eval "$ndCkVar=\"$(eval echo $`echo $ndCkVar`) $varLine\""
            eval echo "$ndCkVar  is  $`echo $ndCkVar`";
        fi
    done
    while [[ -z $GITHUBAUTH ]]; do
        if [[ -n $GITHUBAUTHF ]]; then
            GITHUBAUTH=`echo "$GITHUBAUTHF" | openssl enc -aes-256-cbc -md sha512 -a -d -pbkdf2 -iter 100000 -salt -pass pass:$SALTVALUE`
        elif [[ -z `cat GITHUBAUTHF` ]]; then
            GITHUBAUTH=$(cat GITHUBAUTHF | openssl enc -aes-256-cbc -md sha512 -a -d -pbkdf2 -iter 100000 -salt -pass pass:$SALTVALUE)
        else
            echo "miss/empty GITHUBAUTHF file or var,or it's illegal, Please check !"
            usage
        fi
    done
    while [[ -z $SENDERPWD ]]; do
        if  [[ -n $SENDERPWDF ]]; then
            SENDERPWD=$(echo "$SENDERPWDF" | openssl enc -aes-256-cbc -md sha512 -a -d -pbkdf2 -iter 100000 -salt -pass pass:$SALTVALUE)
        elif [[ -z `cat SENDERPWDF` ]]; then
            SENDERPWD=$(cat SENDERPWDF | openssl enc -aes-256-cbc -md sha512 -a -d -pbkdf2 -iter 100000 -salt -pass pass:$SALTVALUE)
        else
            echo "miss/empty SENDERPWDF file or var,or it's illegal, Please check !"
            usage
        fi
    done
    SCURLC="curl -s -H \"Authorization: token $GITHUBAUTH\" --header \"Accept: application/vnd.github.v3+json\" --location \"$GHURL/search"
    # check sendemail settings
    if [[ -z $TOEMAILLIST || -z $SENDEREMAIL ]]; then usage; fi
    echo "~~~ starting searching ~~~ "
}


# send email to email list
function SendEmailAndCheck() {
    stopTime=$(date "+%s")
    usedTime=$((stopTime-startTime))
    if [[ -f htmlMother.html ]]; then cat htmlMother.html >> htmlEmail; else echo "miss html formwork"; usage; fi
    if [[ -n `diff htmlWorking.html htmlWorking.html.bak` ]];then echo "</tbody></table>" >> htmlWorking.html; cat htmlWorking.html >> htmlEmail ; fi
    if [[ -n `diff htmlPersonal.html htmlPersonal.html.bak` ]];then echo "</tbody></table>" >> htmlPersonal.html; cat htmlPersonal.html >> htmlEmail ; fi
    if [[ -n `diff htmlKeyword.html htmlKeyword.html.bak` ]];then echo "</tbody></table>" >> htmlKeyword.html; cat htmlKeyword.html >> htmlEmail ; fi
    echo "&nbsp;<table class="GeneratedTable"><thead><tr><th colspan="4">"*** time used: $usedTime seconds. ***"</th></tr></thead></table>" >> htmlEmail
    echo "</body></html>" >> htmlEmail
    setEmailToSend="sendemail -f "$SENDEREMAIL" -s "$SMTPADDR" -u "\"$EMAILSUBJECT\"" -a KeywordLinkInUsers.csv -a KeywordLinkInGithub.csv -xu "$SENDEREMAIL" -xp "$SENDERPWD" -o message-content-type=html -o message-file=htmlEmail "
    for te in $TOEMAILLIST; do
        setEmailToSend="$setEmailToSend -t \"$te\" "
    done
    if [[ -n $CCEMAILLIST ]]; then
        for cce in $CCEMAILLIST; do
            setEmailToSend="$setEmailToSend -cc "$cce" "
        done
    fi
    echo "$setEmailToSend"
    eval $setEmailToSend
    echo " ***** time used: $usedTime seconds. *****"
}


function SleepCountDown() {
    SLEEPTIME=$(((RANDOM%10)+30))
    echo "********** [ $BURL ] reach the limit of github api, wait [$SLEEPTIME]s to continue **********"
    for((t=$((SLEEPTIME));t>0;t--)); do echo -n "$t/s "; sleep 1; done
    echo "start again ^_^ "
}


# search keyword one line in repo
function reposSearch() {
    repoList=`echo $ckResult | jq -r ".[].full_name"`
    for repoName in $repoList; do
        repoUrl="$GHURL/$CKTP/$repoName"
        isForked=`curl -s $repoUrl | jq ".fork"`
        while [[ "${isForked}" != "false" ]]; do
            if [[ "$isForked" == "null" ]]; then
                BURL="$repoUrl"
                SleepCountDown
                isForked=`curl -s $repoUrl | jq ".forks"`
            elif [[ "$isForked" == "true" ]]; then
                read isForked repoName < <(echo $(curl -s $repoUrl | jq -r ".parent.fork, .parent.full_name "))
                echo "this is forked repo from [ $repoName ]"
                repoUrl="$GHURL/$CKTP/$repoName"
            fi
        done
        for kwd in $KWDLIST; do
            eurlc="$SCURLC/code?q=$kwd+repo:$repoName&per_page=$PERPAGE\""
            kwdResult=`eval $eurlc`
            while [[ `echo $kwdResult | jq '.? | has("message")'` == true ]]; do
                echo $kwdResult | jq '.message'
                BURL="$eurlc"
                SleepCountDown
                kwdResult=`eval $eurlc`
            done
            total_count=$(echo $kwdResult | jq ".total_count")
            if [[ $total_count -gt $LIMIT ]]; then
                kwdLink="$userName,$total_count,$kwd,$CKTP,$repoName"
                fileHtmlUrl=`echo $kwdResult | jq ".items[].html_url"`
                echo "$userName $total_count $kwd $repoName"
                echo "<tr><td><a href="https://github.com/$userName">"$userName"</a></td><td>"$CKTP"</td><td>"$total_count"</td><td>"$kwd"</td><td><a href="https://github.com/$repoName">"$repoName"</a></td></tr>" >> htmlPersonal.html
                for fileHUrl in $fileHtmlUrl; do
                    kwdLink="$kwdLink,$fileHUrl"
                done
                if [[ $total_count -gt $PERPAGE ]]; then
                    #if [[ $((total_count%PERPAGE)) -eq $limit ]]; then totalPage=$((total_count/PERPAGE)); else totalPage=$((total_count/PERPAGE+1)); fi
                    totalPage=$((total_count/PERPAGE+1))
                    for page in `seq 2 $totalPage`; do
                        eurlc="$SCURLC/code?q=$kwd+repo:$repoName&per_page=$PERPAGE&page=$page\""
                        kwdResult=`eval "$eurlc"`
                        while [[ `echo $kwdResult | jq '.? | has("message")'` == true ]]; do
                            echo $kwdResult | jq '.message'
                            BURL="$eurlc"
                            SleepCountDown
                            kwdResult=`eval $eurlc`
                        done
                        fileHtmlUrl=`echo $kwdResult | jq ".items[].html_url"`
                        for fileHUrl in $fileHtmlUrl; do
                            kwdLink="$kwdLink,$fileHUrl"
                        done
                    done
                fi
                echo "$kwdLink" >> KeywordLinkInUsers.csv
            fi
        done
    done
}


#search following username
function followingSearch() {
    followingList=`echo $ckResult | jq -r ".[].login"`
    ALLFOLLOWING="$ALLFOLLOWING $followingList"
#    for fu in $followingList; do
#        EMAILTXT="$EMAILTXT [ $fu ]  "
#    done
}


function gistsSearch() {
    # read gistsUrlList gistsHUrlList < <(echo $ckResult | jq -r ".[].url, .[].html_url")
    gistsIdList=`echo $ckResult | jq -r ".[].id"`
    for gid in $gistsIdList; do
        gscResult=`curl -s "$GHURL/$CKTP/$gid"`
        while [ "$(echo $gscResult | jq '.? | has("message")')" == true ]; do
            echo $gscResult | jq '.message'
            BURL="$GHURL/$CKTP/$gid"
            SleepCountDown
            gscResult=`curl -s "$GHURL/$CKTP/$gid"`
        done
        for kwd in $KWDLIST ; do
            gContent=`echo $gscResult | jq ".files[].content"`
            echo "gist context is $gContent"
            if [[ $gContent == *"$kwd"* ]]; then
                echo "kwd is $kwd"
                gistName=`echo $gscResult | jq ".files[].filename"`
                echo "<tr><td><a href="https://github.com/$userName">"$userName"</a></td><td>"$CKTP"</td><td>1</td><td>"$kwd"</td><td><a href="https://$CKTP.github.com/$gid">"$gistName"</a></td></tr>" >> htmlPersonal.html
                echo "$userName,1,$kwd,$CKTP,$gistName,$gContent,https://$CKTP.github.com/$gid" >> KeywordLinkInUsers.csv
                echo "user [ $userName ] has keyword [ $kwd ] in [ $CKTP ] [ $gistName ] [ \"https://$CKTP.github.com/$gid\" ] \n"
            fi
        done
    done

}


function SearchCKTP() {
    for CKTP in $CKTPLIST; do
        if [[ $key == *"$CKTP"* ]] ; then
            cktpUrl="$BASEURL/$userName/$CKTP?per_page=$PERPAGE"
            ckResult=$(curl -s $cktpUrl)
            while [ "$(echo "$ckResult" | jq '.? | has("message")')" == true ]; do
                echo $ckResult | jq '.message'
                BURL="$cktpUrl"
                SleepCountDown
                ckResult=$(curl -s $cktpUrl)
            done
            "$CKTP"Search
            if [[ ${myarray[$key]} -gt $PERPAGE ]]; then
                totalPage=$(($((${myarray[$key]}/$PERPAGE))+1))
                for page in `seq 2 $totalPage`; do
                    cktpUrl="$BASEURL/$userName/$CKTP?per_page=$PERPAGE&page=$page"
                    ckResult=$(curl -s $cktpUrl)
                    while [ "$(echo "$ckResult" | jq '.? | has("message")')" == true ]; do
                        echo $ckResult | jq '.message'
                        BURL="$cktpUrl"
                        SleepCountDown
                        ckResult=$(curl -s $cktpUrl)
                    done
                    "$CKTP"Search
                done
            fi
        fi
    done
}


# check user info about [ CKTPLIST ]
# <tr><td>heliangdong</td><td>4</td><td>public_repo</td></tr>
function SearchUserInfo() {
    for userName in $USERNAMELIST; do
        if [[ $CKDUNLIST != *"$userName"* ]]; then
            CKDUNLIST="$CKDUNLIST $userName"
            echo -e "user link is: \n $BASEURL/$userName"
            declare -A myarray;
            set -f;
            while IFS="=" read -r key value ; do
                myarray[$key]="$value"
            done < <(curl -s $BASEURL/$userName | jq -r "$JQ2A");
            while [[ "${myarray["login"]-}" != "$userName" ]]; do
                BURL="$BASEURL/$userName"
                SleepCountDown
                declare -A myarray;
                while IFS="=" read -r key value ; do
                    myarray[$key]="$value"
                done < <(curl -s $BASEURL/$userName | jq -r "$JQ2A");
            done
            for key in "${!myarray[@]}"; do
                if [[ $USERGITHUBTYPE == *"$key"* ]] && [[ ${myarray[$key]} -gt $LIMIT ]] ; then
                    isSend=1
                    if [[ $WKUNLIST == *"$userName"* ]]; then
                        echo "[ $userName ]  created [ ${myarray[$key]} ]  [ $key ], is a [ working ] account, Please inform related to delete it immediately !"
                        echo "<tr><td><a href="https://github.com/$userName">"$userName"</a></td><td>"${myarray[$key]}"</td><td>"$key"</td></tr>" >> htmlWorking.html
                    elif [[ $PSUNLIST == *"$userName"* ]]; then
                        echo "[ $userName ]  [ ${myarray[$key]} ]  [ $key ],  a [ personal ] account, starting search related information:"
                        SearchCKTP
                    else
                        echo " [ $userName ] is a user followd by PSUNLIST list. "
                        SearchCKTP
                    fi
                fi
            done
        fi
        echo " checked username list are $CKDUNLIST "
    done
}


# seach keyword in all github
function SearchKeyword(){
    for SCTP in $SCTPLIST; do
        echo "SCTP is $SCTP, SCKWDLIST is [ $SCKWDLIST ]"
        for sckwd in $SCKWDLIST; do
            echo "sckwd is $sckwd"
            SCURLCA="$SCURLC/$SCTP?q=$sckwd&per_page=$PERPAGE\""
            scKwdResult=`eval "$SCURLCA"`
            while [[ `echo "$scKwdResult" | jq '.? | has("message")'` == true ]]; do
                echo $scKwdResult | jq '.message'
                BURL="$SCURLCA"
                SleepCountDown
                scKwdResult=`eval $SCURLCA`
            done
            total_count=`echo $scKwdResult | jq ".total_count"`
            if [[ $total_count -gt $LIMIT ]]; then
                allItemHurl=`echo $scKwdResult | jq ".items[].html_url"`
                echo "$sckwd,$total_count,$SCTP" >> KeywordLinkInGithub.csv
                echo "<tr><td>"$sckwd"</td><td>"$total_count"</td><td>"$SCTP"</td></tr>" >> htmlKeyword.html
                for i in $allItemHurl; do
                    echo $i >> KeywordLinkInGithub.csv
                done
                if [[ $total_count -gt $PERPAGE ]]; then
                    # if [[ $((total_count%PERPAGE)) -eq $limit ]]; then totalPage=$((total_count/PERPAGE)); else totalPage=$((total_count/PERPAGE+1)); fi
                    totalPage=$((total_count/PERPAGE+1))
                    for page in `seq 2 $totalPage`; do
                        SCURLCA="$SCURLC/$SCTP?q=$sckwd&per_page=$PERPAGE&page=$page\""
                        echo "$SCURLCA"
                        scKwdResult=`eval "$SCURLCA"`
                        while [[ `echo $scKwdResult | jq '.? | has("message")'` == true ]]; do
                            echo $scKwdResult | jq '.message'
                            BURL="$SCURLCA"
                            SleepCountDown
                            scKwdResult=`eval $SCURLCA`
                        done
                        allItemHurl=`echo $scKwdResult | jq ".items[].html_url"`
                        for i in $allItemHurl; do
                            echo $i >> KeywordLinkInGithub.csv
                        done
                    done
                fi
            fi
        done
    done
}


function HaltAndSendEmail() {
    echo "halted by ctrl+c, checked users: [ $CKDUNLIST ], sending email"
    if [[ $isSend -gt $LIMIT  ]] ;then
        echo " found illegal info , Sending Email Now";
        SendEmailAndCheck
    fi
    exit 2
}


main() {
    startTime=$(date "+%s")
    if [[ -f KeywordLinkInUsers.csv ]]; then eval mv KeywordLinkInUsers.csv KeywordLinkInUsers.csv.`date | sed 's/ /-/g'`.bak; fi
    if [[ -f KeywordLinkInGithub.csv ]]; then eval mv KeywordLinkInGithub.csv KeywordLinkInGithub.csv.`date | sed 's/ /-/g'`.bak; fi
    if [[ -f htmlWorking.html ]]; then eval mv htmlWorking.html htmlWorking.html.`date | sed 's/ /-/g'`.bak; fi
    if [[ -f htmlWorking.html.bak ]]; then eval cp htmlWorking.html.bak htmlWorking.html; fi
    if [[ -f htmlPersonal.html ]]; then eval mv htmlPersonal.html htmlPersonal.html.`date | sed 's/ /-/g'`.bak; fi
    if [[ -f htmlPersonal.html.bak ]]; then eval cp htmlPersonal.html.bak htmlPersonal.html; fi
    if [[ -f htmlKeyword.html ]]; then eval mv htmlKeyword.html htmlKeyword.html.`date | sed 's/ /-/g'`.bak; fi
    if [[ -f htmlKeyword.html.bak ]]; then eval cp htmlKeyword.html.bak htmlKeyword.html; fi
    if [[ -f htmlEmail ]]; then eval mv htmlEmail htmlEmail.`date | sed 's/ /-/g'`.bak; fi
    CheckVar
    trap 'HaltAndSendEmail' 2
    USERNAMELIST="$WKUNLIST  $PSUNLIST"
    if [[ -n $USERNAMELIST ]]; then SearchUserInfo; fi
    if [[ -n $SCKWDLIST ]]; then SearchKeyword; fi
    if [[ $ISSCF -gt $LIMIT ]]; then
        echo "ALLFOLLOWING are $ALLFOLLOWING"
        USERNAMELIST="$ALLFOLLOWING"
        SearchUserInfo
    fi
    if [[ $isSend -gt $LIMIT  ]] ;then
        echo " found illegal info , Sending Email Now";
        SendEmailAndCheck
    fi
}


main
