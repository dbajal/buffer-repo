#!/bin/bash -x
plan_dir=$HOME/.planner
plan_file=$plan_dir/day_plan
backup_dir=$HOME/.plan_backup
export DISPLAY=:0
#konsolekalendar --calendar ~/.kde4/share/apps/kalarm/calendar.ics --view --end-time $(date --date='+30 minutes' "+%R") --export-type csv 2>/dev/null
#"20 февраля 2017","11:11","20 февраля 2017","11:11","","","","KAlarm-481498723.859"

function translate_task_name {
	echo $1 | python $HOME/bin/cy_to_lat_trans.py | tr -cd '[[:alpha:]][[:alnum:]] ' | sed 's/\ /_/g'
}

### create
function create_plan {
        test -d $plan_dir || mkdir -p $plan_dir
	test -f $plan_file && exit 0
	lockfile -r 0 -l 620 $plan_dir/.asking || exit 0
	plan="";
	while test -z "$plan"; do
		plan=$(kdialog --textinputbox "Enter day plan(newline as delimeter, no \" syms)");
		grep -q \" <<< "$plan" && plan="";
	done;
	while read LINE; do
		task=$(translate_task_name "$LINE")
		echo 0 > $plan_dir/$task
		echo $task \"$LINE\" >> $plan_file
	done <<< "$plan"
	rm -f $plan_dir/.asking;
}

### clear
function clear_plan {
	rm -f /tmp/targetlock $plan_dir/.asking;
	! test -f $plan_file && exit 0;
        killall kdialog;

        current_date=$(date +"%Y%m%d");
        test -d $backup_dir || mkdir $backup_dir;

        cp -r $plan_dir $backup_dir/$current_date;

	rm -f $plan_dir/*
}

function ask_new_plan {
	choice="";
	while test -z "$choice"; do
		choice=$(kdialog --inputbox "What other? (no \" syms)");
		grep -q \" <<< "$choice" && choice="";
	done;
	task=$(translate_task_name "$choice")
	if ! grep -q "$task \"$choice\"" $plan_file; then
		echo 0 > $plan_dir/$task;
		echo $task \"$choice\" >> $plan_file;
	fi;
	echo $task;
}

### set kalarm for next 10/30 min
function plan_detailed_next {
	planned=$(cat $plan_file);
	command="--menu \"What are you going to do?\" $planned other \"Other\""
	choise="";
	while test -z "$choice"; do
		choice=$(echo $command | xargs kdialog);
	done
        if test "$choice" == "other"; then
            choice=$(ask_new_plan);
        fi;

	details="";
	while test -z "$details"; do
		details=$(kdialog --inputbox "What exactly for '$choice'?");
	done

        task_template="";
        while test -z "$task_template"; do
                task_template=$(kdialog --menu "Task type" short Short long Long);
        done;

        timelength=10;
        test "$task_template" == "long" && timelength=32;
        kalarm -k -t $(python -c "import datetime; print (datetime.datetime.now() + datetime.timedelta(minutes=${timelength})).strftime('%H:%M')") "${choice} ${details}";

        current=$(cat $plan_dir/$choice 2>/dev/null)
        test -z "$current" && curent=0;
        current=$[$current+$timelength];
        echo $current > $plan_dir/$choice;
}

### update
function update_plan {
	test $[$(DISPLAY=:0 xprintidle)/1000] -gt 300 && exit 0

	lockfile -r 0 -l 620 /tmp/targetlock || exit 0

        ! test -f $plan_file && create_plan && exit 0

	exit_code=1;
	while ! test "$exit_code" -eq "0"; do
        	current_task=$(konsolekalendar --calendar $HOME/.kde4/share/apps/kalarm/calendar.ics --view --end-time $(date --date='+30 minutes' "+%R") --export-type csv 2>/dev/null)

	        # there is task - everything's fine
        	if test -z "${current_task}"; then
                	plan_detailed_next;
	                exit_code=$?;
        	else
                	exit_code=0;
	        fi;
	done

	rm -f /tmp/targetlock
}

function update_short_plan {
	! test -f $plan_file && create_plan && exit 0

	choice=$(ask_new_plan);
	current=0;
	echo $current > $plan_dir/$choice;
}

function render_plan {
        :>/tmp/.done_plan;
        while read LINE; do
                task_text=$(echo "$LINE" | cut -d ' ' -f2-);
                task=$(translate_task_name "$task_text")
                echo $(cat $plan_dir/$task) $task_text >> /tmp/.done_plan;
        done < $plan_file;
        plan_text_formatted=$(/usr/bin/env python $HOME/bin/format_plan.py /tmp/.done_plan);
        echo "$plan_text_formatted" > /tmp/.done_plan;
	echo /tmp/.done_plan;
}

function render_mail_plan {
	mail_pass=$(/usr/lib/ssh/ksshaskpass tm)
	plan=$(render_plan)

	echo 'Присутствие: 10:00 - 19:00

Сделано:
';

	while read LINE; do
		egrep -qi "стендап|планирование дня" <<< "$LINE" && continue;
        	echo '  - x '$LINE;
	done <<< "$(cat $plan | cut -d '"' -f2)"

	echo '
План на следующий день:

Проблемы:

Коммуникации:';
}

function show_plan {
	rendered_plan=$(render_plan);
        kdialog --textbox $rendered_plan 500 300;
}

function plan_not_found {
	echo "No such plan: "$1
	exit 1
}

function show_history_plan {        
	test -n "$1" && plan_dir=$backup_dir/$1 && plan_file=$plan_dir/day_plan;
        test -d $plan_dir || plan_not_found $1
        show_plan;
}

function choose_history_plan {
	dates=$(ls -1r $backup_dir);
	
	command="--menu \"What u did?\" $(for i in $dates; do echo $i $i; done)";
	choice_date=$(echo $command | xargs kdialog);
        show_history_plan $choice_date;
}

command_given=$1
! egrep -q "^(choose_history|clear|update|update_short|show|show_history|render|render_mail)$" <<< "$command_given" && echo "Usage: $0 <choose_history|update|update_short|show|show_history|render|render_mail>" && exit 1

${command_given}_plan $2
