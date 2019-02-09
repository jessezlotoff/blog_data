// Test of Javascript
// Jesse Zlotoff
// 2/6/19

start=0;

//--------

function intInput(evt) {
  return(evt.keyCode >= 49 && evt.keyCode <= 57)
}

//--------

function countBlank() {
  var cnt = 0;
  var field, text;


  for (r=1; r<10; r++) {
    for (c=1; c<10; c++) {
      field = "c"+r+"_"+c;
      if (document.getElementById(field).innerHTML == "") {
        cnt += 1;
      }
    }
  }
  text = cnt + " square(s) empty";
  alert(text);
}

//--------

function allowEdit(id) {

  document.getElementById(id).setAttribute('contentEditable', 'true');
  document.getElementById(id).setAttribute('onKeyPress', 'return (this.innerHTML.length<=0 && intInput(event));');

}

//--------

function setupGrid(numList) {
  var i = 0;

  for (r=1; r<10; r++) {
    for (c=1; c<10; c++) {
      field = "c"+r+"_"+c;
      if (numList[i]!=0) { // existing number
        document.getElementById(field).innerHTML = numList[i];
      } else {
        document.getElementById(field).innerHTML = "";
        allowEdit(field);
      }
      i += 1;
    }
  }
}

//--------

function clearGrid() {

  for (r=1; r<10; r++) {
    for (c=1; c<10; c++) {
      field = "c"+r+"_"+c;
      document.getElementById(field).innerHTML = "";
      document.getElementById(field).setAttribute('contentEditable', 'false');
    }
  }
}

//--------

function checkGrid(solved) {
  var err = 0;
  var cor = 0;
  var i = 0;

  for (r=1; r<10; r++) {
    for (c=1; c<10; c++) {
      field = "c"+r+"_"+c;
      raw = document.getElementById(field).innerHTML;
      if (raw != solved[i] && raw!="") { // incorrect
        err += 1;
        document.getElementById(field).style.backgroundColor="#F3C9C9";
      } else if (raw=="") { // blank
        document.getElementById(field).style.backgroundColor="#FFFFFF";
      } else {
        cor += 1;
        document.getElementById(field).style.backgroundColor="#FFFFFF";
        document.getElementById(field).setAttribute('contentEditable', 'false');
      }
      i += 1;
    } // c
  } // r

  stat = "Status:<br/>";
  if (err == 1) {
    stat = stat + "1 incorrect square";
  } else if (err > 1) {
    stat = stat + err + " incorrect squares";
  } else {
    if (cor == 81) { // solved
      time = stopTimer();
      alert("Congratulations! Puzzle completed in " + time);
      stat = stat + "Puzzle complete";
    } else {
      stat = stat + "All items correct so far";
    }
  }
  document.getElementById('status').innerHTML = stat;

}

//--------

function curSquare() {
  var sel = window.getSelection();
  var range = sel.getRangeAt(0);
  var cur = range.startContainer;
  var par = cur.parentNode;
  if (cur.tagName == "TD") { // empty cell
    var id = cur.id;
  } else {
    var id = par.id;
  }
    return(id);
}

//--------

function revealSquare(solved) {
  var cur = curSquare();
  if (cur.length == 4) {
    var r = parseInt(cur.substring(1,2));
    var c = parseInt(cur.substring(3,4));
    var i = (9 * (r-1)) + c - 1;
    var confirmed = confirm('Are you sure you want to reveal this?');
    if(confirmed) {
      document.getElementById(cur).innerHTML = solved[i];
      document.getElementById(cur).style.backgroundColor="#FFFFFF";
      document.getElementById(cur).setAttribute('contentEditable', 'false');
    }
  }
}

//--------

function checkSquare(solved) {
  var cur = curSquare();
  if (cur.length == 4) {
    var r = parseInt(cur.substring(1,2));
    var c = parseInt(cur.substring(3,4));
    var i = (9 * (r-1)) + c - 1;
    raw = document.getElementById(cur).innerHTML;
    if (raw != solved[i] && raw!="") { // incorrect
      document.getElementById(cur).style.backgroundColor="#F3C9C9";
    } else {
      document.getElementById(cur).style.backgroundColor="#FFFFFF";
    }
    if (raw == solved[i] && raw!="") { // correct
      document.getElementById(cur).setAttribute('contentEditable', 'false');
    }
  } // cur length 4
}

//--------

function startTimer() {

  var date = new Date();
  var timestamp = date.getTime();
  start = timestamp;

}

//--------

function msToTime(duration) { // from Stack Overflow
  var milliseconds = parseInt((duration % 1000) / 100),
    seconds = parseInt((duration / 1000) % 60),
    minutes = parseInt((duration / (1000 * 60)) % 60),
    hours = parseInt((duration / (1000 * 60 * 60)) % 24);

  hours = (hours < 10) ? "0" + hours : hours;
  minutes = (minutes < 10) ? "0" + minutes : minutes;
  seconds = (seconds < 10) ? "0" + seconds : seconds;

  return hours + ":" + minutes + ":" + seconds;
}

//--------

function stopTimer() {

  var date = new Date();
  var timestamp = date.getTime();
  elapsed = msToTime(timestamp - start);
  return(elapsed);

}

//--------

function getPuzzlelocal() {
  var site = 'http://127.0.0.1:5000/puzzle';
  var Httpreq = new XMLHttpRequest(); // a new request
  Httpreq.open("GET",site,false);
  Httpreq.send(null);
  text = Httpreq.responseText;
  return JSON.parse(text);
}

//--------

async function getSetupPuzzle() {
  var site = 'https://jessezlotoff.pythonanywhere.com/puzzle';

  const response = await fetch(site, { method: 'GET', mode: 'cors', headers: {
            "Accept": "application/json"}
      });
  const puz = await response.json();

  unsolved = puz.to_solve;
  solution = puz.solved;
  setupGrid(puz.to_solve);
  startTimer();

}

//--------

function test() {
  puzzle = setupNew();
  //alert(JSON.stringify(puzzle));
  alert(puzzle.to_solve);
}

//--------

function newPuzzle() {
  puzzle = getPuzzle();
  setupGrid(puzzle.to_solve);
  startTimer();

}

//-------------------------------
