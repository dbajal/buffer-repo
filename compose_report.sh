message="$(/bin/bash $HOME/bin/do_plan.sh render_mail | sed 's/\ /\&nbsp;/g')"
echo $message
datet=$(date +%d.%m.%Y)
m_to='p@u'
string_m="to='${m_to}',cc='${m_cc}',bcc='${m_bcc}',subject='Отчёт ${datet}',body='${message}'"
echo $string_m
thunderbird --display :0.0 -compose "$string_m"
