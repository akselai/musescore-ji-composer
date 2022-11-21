import QtQuick 2.2 // TODO : HEJI note name support
import MuseScore 3.0
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.3
import QtQuick.Layouts 1.1
import QtQuick.Dialogs 1.1

MuseScore {
      menuPath: "Plugins.ji_composer"
      description: "A control panel for composing in just intonation (JI)."
      version: "1.0"
      requiresScore: false
      pluginType: "dialog"
      dockArea:   "left"
      width: 200
      height: 75
      
      function applyToNotesInSelection(func, params) { 
            var cursor = curScore.newCursor();
            cursor.rewind(0);
            var startStaff;
            var endStaff;
            var endTick;
            var fullScore = false;
            if (!cursor.segment) { // no selection
                  fullScore = true;
                  startStaff = 0; // start with 1st staff
                  endStaff = curScore.nstaves - 1; // and end with last
            } else {
                  startStaff = cursor.staffIdx;
                  cursor.rewind(2);
                  if (cursor.tick === 0) {
                        // this happens when the selection includes
                        // the last measure of the score.
                        // rewind(2) goes behind the last segment (where
                        // there's none) and sets tick=0
                        endTick = curScore.lastSegment.tick + 1;
                  } else {
                        endTick = cursor.tick;
                  }
                  endStaff = cursor.staffIdx;
            }
            console.log(startStaff + " - " + endStaff + " - " + endTick)
            
            
            for (var staff = startStaff; staff <= endStaff; staff++) {
                  for (var voice = 0; voice < 4; voice++) {
                        cursor.rewind(1); // sets voice to 0
                        cursor.voice = voice; //voice has to be set after goTo
                        cursor.staffIdx = staff;

                        if (fullScore)
                              cursor.rewind(0);
                        
                        var pointer = 0;
                        while (cursor.segment && (fullScore || cursor.tick < endTick)) {
                              if (cursor.element && cursor.element.type === Element.CHORD) {
                              
                                    var curlen = cursor.segment.annotations.length;
                                    
                                    var graceChords = cursor.element.graceNotes;
                                    for (var i = 0; i < graceChords.length; i++) {
                                          // iterate through all grace chords
                                          var graceNotes = graceChords[i].notes;
                                          for (var j = 0; j < graceNotes.length; j++) {
                                                /*
                                                if (curlen != 0) {
                                                      func(graceNotes[j], cursor.segment.annotations[0].text);
                                                } else func(graceNotes[j], 0);
                                                */
                                          }
                                    }
                                    var notes = cursor.element.notes;
                                    var stackNotes = [];
                                    var stackAccidental = [];
                                    for (var k = 0; k < notes.length; k++) {
                                          var note = notes[k];
                                          console.log("octave: " + baseOctave(note));
                                          console.log("base: " + k + " " + baseNote(note));
                                          if (k != 0) {
                                                if(baseNote(notes[k - 1]) != baseNote(note) || baseOctave(notes[k - 1]) != baseOctave(note)) {
                                                      console.log(k);
                                                }
                                          }
                                    }
                                    for (var k = 0; k < notes.length; k++) {
                                          if (curlen != 0) {
                                                var commaList = cursor.segment.annotations[0].text.split("\n");
                                                func(note, commaList[commaList.length - k - 1]);
                                          } else {
                                                func(note, "*");
                                          }
                                    }
                              }
                              pointer++;
                              cursor.next();
                        }
                  }
            }
      }
      
      function tune(note, comma) {
            if (comma[0] == "*" && note.accidentalType > 7) { // HEJI mode
                  note.tuning = baseNoteTuning(baseNote(note)) + sharpFlatTuning(note) + arrowTuning(note);
            } else { // FJS mode
                  note.tuning = baseNoteTuning(baseNote(note)) + sharpFlatTuning(note) + otonalToComma(comma);
            }
      }
      
      function otonalToComma(str) {
            str = str.split("/");
            var a = primeFactors(str[0]);
            var totalComma = 0;
            for (var i = 0; i < a.length; i++) {
                  totalComma += fundamentalCommas(a[i]);
            }
            
            if(str.length != 0) {
                  var b = primeFactors(str[1]);
                  for (var i = 0; i < b.length; i++) {
                        totalComma -= fundamentalCommas(b[i]);
                  }
            }
            return totalComma;
      }
      
      /*************************************
      *  the functions below take a string *
      *  as a rational number argument,    *
      *  i.e. 256/243 etc.                 *
      *************************************/
      
      function lowerTerms(s) {
            var str = s.split("/");
            var g = gcd(str[0], str[1]);
            return div(str[0], g) + "/" + div(str[1], g);
      }
      
      function regularReduce(s) {
            var str = s.split("/");
            var dir = smaller(str[0], str[1]);
            var frac = div(str[0], str[1]);
            var frac1 = div(str[1], str[0]);
            if (dir) return lowerTerms(mul(str[0], dbl(flog2(frac1))) + "/" + str[1]);
            else return lowerTerms(str[0] + "/" + mul(str[1], flog2(frac)));
      }
      
      function balancedReduce(s) {
            var str = regularReduce(s).split("/");
            if (floatDiv(str[0], str[1], 16) > Math.sqrt(2)) str[1] *= 2;
            return lowerTerms(str[0] + "/" + str[1]);
      }
      
      function rtc (ratio) {
            var str = ratio.split("/");
            return 1200 * Math.log(floatDiv(str[0], str[1], 16)) / Math.log(2);
      }
      
      function ctr (cents) {
            return Math.exp(2, cents/1200);
      }
      
      function baseNoteTuning(abcdefg) {
            switch (abcdefg) {
            case "A": return 0; break;
            case "B": return rtc("9/8") - 200; break;
            case "C": return rtc("32/27") - 300; break;
            case "D": return rtc("4/3") - 500; break;
            case "E": return rtc("3/2") - 700; break;
            case "F": return rtc("128/81") - 800; break;
            case "G": return rtc("16/9") - 1000; break;
            default: return 0;
            }
      }
      
      function sharpFlatTuning(note) {
            var offset = (note.accidentalType+0 <= 7 ? 100 : 0);
            return (rtc("2187/2048") - offset) * accidentalValWithArrows(note);
      }
      
      function arrowTuning(note) {
            if (note.accidentalType <= 60 && 31 <= note.accidentalType) {
                  return rtc("81/80") * accidentalArrow(note);
            }
      }
      
      function fundamentalCommas(prime) {
            prime += ""; // convert to string!
            var ratio;
            switch (prime) {
            case "5": ratio = "80/81"; break;
            case "7": ratio = "63/64"; break;
            case "11": ratio = "33/32"; break;
            case "13": ratio = "1053/1024"; break;
            case "17": ratio = "4131/4096"; break;
            case "19": ratio = "513/512"; break;
            case "23": ratio = "736/729"; break;
            case "29": ratio = "261/256"; break;
            case "31": ratio = "248/243"; break;
            case "37": ratio = "37/36"; break;
            case "41": ratio = "82/81"; break;
            case "43": ratio = "129/128"; break;
            case "47": ratio = "47/48"; break;
            case "53": ratio = "53/54"; break;
            case "59": ratio = "236/243"; break;
            case "61": ratio = "244/243"; break;
            default: ratio = "1/1";
            }
            return rtc(ratio);
      }
      
      function HEJICommas(prime) {
            prime += ""; // convert to string!
            var ratio;
            switch (prime) {
            case "5": ratio = "80/81"; break;
            case "7": ratio = "63/64"; break;
            case "11": ratio = "33/32"; break;
            case "13": ratio = "26/27"; break;
            case "17": ratio = "4131/4096"; break;
            case "19": ratio = "513/512"; break;
            case "23": ratio = "736/729"; break;
            case "29": ratio = "261/256"; break;
            case "31": ratio = "248/243"; break;
            case "37": ratio = "37/36"; break;
            case "41": ratio = "82/81"; break;
            case "43": ratio = "129/128"; break;
            case "47": ratio = "752/729"; break;
            case "53": ratio = "53/54"; break;
            case "59": ratio = "236/243"; break;
            case "61": ratio = "244/243"; break;
            default: ratio = "1/1";
            }
            return rtc(ratio);
      }
      
      function fshift(prime) {
            prime += "";
            switch (prime) {
            case "5": return 4; break;
            case "7": return -2; break;
            case "11": return -1; break;
            case "13": return -4; break;
            case "17": return -5; break;
            case "19": return -3; break;
            case "23": return 6; break;
            case "29": return -2; break;
            case "31": return 5; break;
            case "37": return 2; break;
            case "41": return 4; break;
            case "43": return -1; break;
            case "47": return 1; break;
            case "53": return 3; break;
            case "59": return 5; break;
            case "61": return 5; break;
            default: return 0;
            }
      }
      
      function HEJIfshift(prime) {
            prime += "";
            switch (prime) {
            case "5": return 4; break;
            case "7": return -2; break;
            case "11": return -1; break;
            case "13": return 3; break;
            case "17": return 7; break;
            case "19": return -3; break;
            case "23": return 6; break;
            case "29": return -2; break;
            case "31": return 0; break;
            case "37": return 2; break;
            case "41": return 4; break;
            case "43": return -1; break;
            case "47": return 1; break;
            case "53": return 3; break;
            case "59": return 5; break;
            case "61": return 5; break;
            default: return 0;
            }
      }
      
      function baseOctave(note) {
            return Math.floor((note.pitch - accidentalVal(note))/12) - 1;
      }
      
      function baseNote(note) {
            var midiNum = (note.pitch - accidentalVal(note)) % 12;
            switch (midiNum) {
            case 9: return "A"; break;
            case 11: return "B"; break;
            case 0: return "C"; break;
            case 2: return "D"; break;
            case 4: return "E"; break;
            case 5: return "F"; break;
            case 7: return "G"; break;
            default: console.log(midiNum + "o h   n o" + accidentalVal(note));
            }
      }
      
      function accidentalVal(note) {
      //console.log(note.accidentalType+0);
      var acx = note.accidentalType + 0;
      // why +0?
      // there are a lot of unsolved problems in the world
      // the equivalence relations in javascript is one of them
            switch (acx) {
            case 0: return 0; break;  // nothing
            case 1: return -1; break; // b
            case 2: return 0; break;  // natural
            case 3: return 1; break;  // #
            case 4: return 2; break;  // ##
            case 5: return -2; break; // bb
            case 6: return 3; break;  // ###
            case 7: return -3; break; // bbb
            default: return 0;
            }
      }
      
      function accidentalValWithArrows(note) {
      console.log(note.accidentalType+0);
      var acx = note.accidentalType + 0;
            switch (acx) {
            case 0: return 0; break;  // nothing
            case 1: return -1; break; // b
            case 2: return 0; break;  // natural
            case 3: return 1; break;  // #
            case 4: return 2; break;  // ##
            case 5: return -2; break; // bb
            case 6: return 3; break;  // ###
            case 7: return -3; break; // bbb
            case 53: return 0; break; // vvv
            case 43: return 0; break; // vv
            case 33: return 0; break; // v
            case 38: return 0; break; // ^
            case 48: return 0; break; // ^^
            case 58: return 0; break; // ^^^
            case 52: return -1; break;// bvvv
            case 42: return -1; break;// bvv
            case 32: return -1; break;// bv
            case 37: return -1; break;// b^
            case 47: return -1; break;// b^^
            case 57: return -1; break;// b^^^
            case 54: return 1; break; // #vvv
            case 44: return 1; break; // #vv
            case 34: return 1; break; // #v
            case 39: return 1; break; // #^
            case 49: return 1; break; // #^^
            case 59: return 1; break; // #^^^
            case 51: return -2; break;// bbvvv
            case 41: return -2; break;// bbvv
            case 31: return -2; break;// bbv
            case 36: return -2; break;// bb^
            case 46: return -2; break;// bb^^
            case 56: return -2; break;// bb^^^
            case 55: return 2; break; // ##vvv
            case 45: return 2; break; // ##vv
            case 35: return 2; break; // ##v
            case 40: return 2; break; // ##^
            case 50: return 2; break; // ##^^
            case 60: return 2; break; // ##^^^
            default: return 0;
            }
      }
      
      function accidentalArrow(note) {
      console.log(note.accidentalType+0);
      var acx = note.accidentalType + 0;
            switch (acx) {
            case 53: return -3; break;// vvv
            case 43: return -2; break;// vv
            case 33: return -1; break;// v
            case 38: return 1; break; // ^
            case 48: return 2; break; // ^^
            case 58: return 3; break; // ^^^
            case 52: return -3; break;// bvvv
            case 42: return -2; break;// bvv
            case 32: return -1; break;// bv
            case 37: return 1; break; // b^
            case 47: return 2; break; // b^^
            case 57: return 3; break; // b^^^
            case 54: return -3; break;// #vvv
            case 44: return -2; break;// #vv
            case 34: return -1; break;// #v
            case 39: return 1; break; // #^
            case 49: return 2; break; // #^^
            case 59: return 3; break; // #^^^
            case 51: return -3; break;// bbvvv
            case 41: return -2; break;// bbvv
            case 31: return -1; break;// bbv
            case 36: return 1; break; // bb^
            case 46: return 2; break; // bb^^
            case 56: return 3; break; // bb^^^
            case 55: return -3; break;// ##vvv
            case 45: return -2; break;// ##vv
            case 35: return -1; break;// ##v
            case 40: return 1; break; // ##^
            case 50: return 2; break; // ##^^
            case 60: return 3; break; // ##^^^
            default: return 0;
            }
      }
      
      function valAccidental(n_) {
            switch (n_) {
            case 0: return Accidental.NATURAL; break;
            case 1: return Accidental.SHARP; break;
            case 2: return Accidental.SHARP2; break;
            case 3: return Accidental.SHARP3; break;
            case -1: return Accidental.FLAT; break;
            case -2: return Accidental.FLAT2; break;
            case -3: return Accidental.FLAT3; break;
            default: return;
            }
      }
      
      property var genericIntervalNames: ["m2", "m6", "m3", "m7", "P4", "P1", "P5", "M2", "M6", "M3", "M7"];
      
      function intervalName(a, mode) {
            a = toVector(a, 31);
            var f = a[2] + 5;
            console.log(a);
            var o = "1";
            var u = "1";
            for (var i = 3; i < a.length; i++) {
                  f += a[i] * (mode == "HEJI" ? HEJIfshift(primePos(i)) : fshift(primePos(i)));
                  if(a[i] > 0) o = mul(o, expon(primePos(i)+"", a[i]+""));
                  if(a[i] < 0) u = mul(u, expon(primePos(i)+"", -a[i]+""));
            }
            console.log(o + " " + u);
            var p = "";
            while (f > 10) {
                  p += "A";
                  f -= 7;
            }
            while (f < 0) {
                  p += "d";
                  f += 7;
            }
            return p + (p == "" ? genericIntervalNames[f] : genericIntervalNames[f].charAt(1))
                  + (o == "1" ? "" : "^" + o) + (u == "1" ? "" : "_" + u);
      }
      
      function interpretIntervalPrefix(str) {
            if (str.includes("-")) {
                  return interpretIntervalPrefixDesc(str);
            } else {
                  return interpretIntervalPrefixAsc(str);
            }
      }
      
      function interpretIntervalPrefixAsc(str) {
            if (str.length == 1) {return;}
            var r = 0;
            if (str.length > 2) {
                  if (str.charAt(0) == "A") r = str.length - 2;
                  else if (str.charAt(0) == "d") r -= str.length - 2;
            }
            var s = str.substring(str.length - 2);
            switch (s) { // centered at A
            case "P1": return r; break;
            case "m2": return r - 1; break;
            case "M2": return r; break;
            case "m3": return r; break;
            case "M3": return r + 1; break;
            case "P4": return r; break;
            case "P5": return r; break;
            case "m6": return r; break;
            case "M6": return r + 1; break;
            case "m7": return r; break;
            case "M7": return r + 1; break;
            case "A1": return r + 1; break;
            case "A2": return r + 1; break;
            case "A3": return r + 2; break;
            case "A4": return r + 1; break;
            case "A5": return r + 1; break;
            case "A6": return r + 2; break;
            case "A7": return r + 2; break;
            case "d1": return r - 1; break;
            case "d2": return r - 2; break;
            case "d3": return r - 1; break;
            case "d4": return r - 1; break;
            case "d5": return r - 1; break;
            case "d6": return r - 2; break;
            case "d7": return r - 2; break;
            default: return;
            }
      }
      
      function interpretIntervalPrefixDesc(str) {
            if (str.length <= 2) {return;}
            var r = 0;
            if (str.length > 3) {
                  if (str.charAt(0) == "A") r += str.length - 2;
                  else if (str.charAt(0) == "d") r = str.length - 2;
            }
            var s = str.substring(str.length - 3);
            console.log(s);
            switch (s) { // centered at A
            case "P-1": return r; break;
            case "m-2": return r + 1; break;
            case "M-2": return r; break;
            case "m-3": return r; break;
            case "M-3": return r - 1; break;
            case "P-4": return r; break;
            case "P-5": return r; break;
            case "m-6": return r; break;
            case "M-6": return r - 1; break;
            case "m-7": return r; break;
            case "M-7": return r - 1; break;
            case "A-1": return r - 1; break;
            case "A-2": return r - 1; break;
            case "A-3": return r - 2; break;
            case "A-4": return r - 1; break;
            case "A-5": return r - 1; break;
            case "A-6": return r - 2; break;
            case "A-7": return r - 2; break;
            case "d-1": return r + 1; break;
            case "d-2": return r + 2; break;
            case "d-3": return r + 1; break;
            case "d-4": return r + 1; break;
            case "d-5": return r + 1; break;
            case "d-6": return r + 2; break;
            case "d-7": return r + 2; break;
            default: return;
            }
      }
      
      function diatonicStep(note, steps) { // default mode is natural minor
            steps = parseInt(steps);
            console.log(steps);
            if (steps == 0 || steps.length > 10) return;
            var midiNum = note - accidentalVal(note);
            if (steps == 1) {return midiNum;}
            var m = midiNum % 12;
            if (steps > 1) {
                  switch (m) {
                  case 9: midiNum += 2; break;
                  case 11: midiNum += 1; break;
                  case 0: midiNum += 2; break;
                  case 2: midiNum += 2; break;
                  case 4: midiNum += 1; break;
                  case 5: midiNum += 2; break;
                  case 7: midiNum += 2; break;
                  default: return;
                  }
            }
            if (steps < -1) {
                  switch (m) {
                  case 9: midiNum -= 2; break;
                  case 11: midiNum -= 2; break;
                  case 0: midiNum -= 1; break;
                  case 2: midiNum -= 2; break;
                  case 4: midiNum -= 2; break;
                  case 5: midiNum -= 1; break;
                  case 7: midiNum -= 2; break;
                  default: return;
                  }
            }
            steps += (steps > 1 ? -1 : 1);
            if (steps == 1 || steps == -1) {return midiNum;} 
            else {return diatonicStep(midiNum, steps)};
      }
      
      function diatonicKeyVal(note, steps) {
            if (steps == 0) return;
            if (steps == 1 || steps == -1) return 0;
            var midiNum = note - accidentalVal(note);
            var m = midiNum % 12;
            // if (m == 9) return 0;
            var n = m + "" + steps;
            console.log(n);
            switch (n) {
            case "112": return 1; break;
            case "115": return 1; break;
            case "03": return -1; break;
            case "06": return -1; break;
            case "07": return -1; break;
            case "26": return -1; break;
            case "42": return 1; break;
            case "53": return -1; break;
            case "54": return -1; break;
            case "56": return -1; break;
            case "57": return -1; break;
            case "73": return -1; break;
            case "76": return -1; break;
            case "0-2": return -1; break;
            case "5-2": return -1; break;
            case "4-3": return 1; break;
            case "9-3": return 1; break;
            case "11-3": return 1; break;
            case "11-4": return 1; break;
            case "5-5": return -1; break;
            case "0-6": return 1; break;
            case "2-6": return 1; break;
            case "4-6": return 1; break;
            case "9-6": return 1; break;
            case "11-6": return 1; break;
            case "4-7": return 1; break;
            case "11-7": return 1; break;
            default: return 0;
            }
      }
      
      function intervalStep(tick, interval, dur_z, dur_n) {            
            var c = curScore.newCursor();
            c.track = 0;
            c.rewindToTick(tick);
            
            var note = c.element.notes[0];
            var midiNum = note.pitch - accidentalVal(note);
            var steps = (interval.charAt(interval.length - 2) == "-" ? "-" : "") + interval.charAt(interval.length - 1);
            var val = diatonicKeyVal(midiNum, steps) + interpretIntervalPrefix(interval) + accidentalVal(note);
            console.log(midiNum + " " + steps + " " + val);
            c.next();
            if (dur_z !== undefined && dur_n !== undefined) {
                  c.setDuration(dur_z, dur_n);
            } else {
                  c.setDuration(1, 4);
            }
            c.addNote(diatonicStep(midiNum, steps));
            c.prev();
            var x = c.element.notes[0];
            console.log(x);
            x.line = noteToLine(x);
            x.accidentalType = valAccidental(val);
      }
      
      function noteToLine(note) {
            var r = 0;
            if (note.pitch - accidentalVal(note) < 69) r += Math.ceil((69 - note.pitch - accidentalVal(note)) / 12) * 7;
            if (note.pitch - accidentalVal(note) >= 81) r -= Math.floor((note.pitch - accidentalVal(note) - 69) / 12) * 7;
            switch (baseNote(note)) {
                  case "A": return r + 5; break;
                  case "B": return r + 4; break;
                  case "C": return r + 3; break;
                  case "D": return r + 2; break;
                  case "E": return r + 1; break;
                  case "F": return r + 0; break;
                  case "G": return r + -1; break;
                  default: return;
            }
      }
      
      function noteTick(note) {
            var esc = 0; 
            while (note.type != Element.SEGMENT) {
                  note = note.parent;
                  if(note.tick >= 0) {console.log(note.tick); return note.tick}; 
                  esc++;		
                  if(esc > 6) {return undefined;}
            }
      }
      
      onRun: {
            // applyToNotesInSelection(tune, true);
            // Qt.quit();
      }
      
      GridLayout {
            anchors.fill: parent
            columns: 3
            rowSpacing: 5
            
            Button {
                  text: "retune!"
                  Layout.columnSpan: 2
                  Layout.fillWidth: true
                  onClicked: {applyToNotesInSelection(tune, true);}
            }
            
            Button {
                  text: "m3"
                  Layout.columnSpan: 1
                  Layout.fillWidth: false
                  onClicked: {
                        stepper("m3");
                  }
            }
            
            Button {
                  text: "M3"
                  Layout.columnSpan: 1
                  Layout.fillWidth: false
                  onClicked: {
                        stepper("M3");
                  }
            }
            Button {
                  text: "m-7"
                  Layout.columnSpan: 1
                  Layout.fillWidth: false
                  onClicked: {
                        stepper("m-7");
                  }
            }
            
            Button {
                  text: "M-6"
                  Layout.columnSpan: 1
                  Layout.fillWidth: false
                  onClicked: {
                        stepper("M-6");
                  }
            }
            
            Button {
                  text: "P-5"
                  Layout.columnSpan: 1
                  Layout.fillWidth: false
                  onClicked: {
                        stepper("P-5");
                  }
            }
            
            Button {
                  text: "P-4"
                  Layout.columnSpan: 1
                  Layout.fillWidth: false
                  onClicked: {
                        stepper("P-4");
                  }
            }
            
            Button {
                  text: "m-3"
                  Layout.columnSpan: 1
                  Layout.fillWidth: false
                  onClicked: {
                        stepper("m-3");
                  }
            }
            
            Button {
                  text: "M-2"
                  Layout.columnSpan: 1
                  Layout.fillWidth: false
                  onClicked: {
                        stepper("M-2");
                  }
            }
      }
      
      Item {
            id: pressKey
            focus: true
            Keys.onPressed: {
                  keyPressEvent(event.key);
            }
      
            function keyPressEvent(key) {
                  console.log(key);
            }
      }
      
      function stepper(interval) {
            curScore.startCmd();
            intervalStep(noteTick(curScore.selection.elements[0]), interval, 1, 4);
            applyToNotesInSelection(tune, true);
            curScore.endCmd();
      }
      
      /*******************
      * fraction methods *
      *******************/
      
      function mul_r(a, b) {
            a = a.split("/");
            b = b.split("/");
            if (b[1] == undefined) return mul(a[0], b[0]) + "/" + a[1];
            if (a[1] == undefined) return mul(a[0], b[0]) + "/" + b[1];
            return mul(a[0], b[0]) + "/" + mul(a[1], b[1]);
      }
      
      function recipr(a) {
            a = a.split("/");
            if (a[1] == undefined) return "1/" + a[0];
            return a[1] + "/" + a[0];
      }
      
      function div_r(a, b) {
            return mul_r(a, recipr(b));
      }
      
      /*********************
      * big number methods *
      *********************/
      

      function add(A, B) {
            var AL = A.length;
            var BL = B.length;
            var ML = Math.max(AL, BL);
            var carry = 0;
            var sum = "";
            for (var i = 1; i <= ML; i++) {
                  var a = +A.charAt(AL - i);
                  var b = +B.charAt(BL - i);
                  var t = carry + a + b;
                  carry = t/10 | 0;
                  t %= 10;
                  sum = (i === ML && carry) ? carry*10 + t + sum : t + sum;
            }
            return sum;
      }
      
      function sub(str1, str2) {  
        var str = "";
        var n1 = str1.length;
        var n2 = str2.length;
        var diff = n1 - n2;
        var carry = 0;
        for (var i = n2 - 1; i >= 0; i--) {
            var sub = ((str1[i + diff].charCodeAt() - '0'.charCodeAt()) - (str2[i].charCodeAt() - '0'.charCodeAt()) - carry);
            if (sub < 0) {
                sub = sub + 10;
                carry = 1;
            }
            else
                carry = 0;
  
            str += sub.toString();
        }
  
        for (var i = n1 - n2 - 1; i >= 0; i--) {
            if (str1[i] == '0' && carry > 0) {
                str += "9";
                continue;
            }
            var sub = ((str1[i].charCodeAt() - '0'.charCodeAt()) - carry);
            if (i > 0 || sub > 0) str += sub.toString();
            carry = 0;
        }

        var aa = str.split('');
        aa.reverse();
        aa = aa.join("").replace(/\b0+/g, '');
        return aa === "" ? "0" : aa;
      }
      
      function mul(strNum1,strNum2){
            var a1 = strNum1.split("").reverse();
            var a2 = strNum2.toString().split("").reverse();
            var aResult = new Array;
 
            for ( var iterNum1 = 0; iterNum1 < a1.length; iterNum1++ ) {
                  for ( var iterNum2 = 0; iterNum2 < a2.length; iterNum2++ ) {
                        var idxIter = iterNum1 + iterNum2;    // Get the current array position.
                        aResult[idxIter] = a1[iterNum1] * a2[iterNum2] + ( idxIter >= aResult.length ? 0 : aResult[idxIter] );
                        
                        if ( aResult[idxIter] > 9 ) {    // Carrying
                              aResult[idxIter + 1] = Math.floor( aResult[idxIter] / 10 ) + ( idxIter + 1 >= aResult.length ? 0 : aResult[idxIter + 1] );
                              aResult[idxIter] %= 10;
                        }
                   }
             }
             return aResult.reverse().join("");
      }
      
      function div(a, b) {
            var c = "1";
            var n = "0";
            if (larger(b, a)) return "0";
            if (b == a) return "1";
            while (smallerOrEqual(b, a)) {
                  b = dbl(b);
                  c = dbl(c);
            }
            
            b = half(b);
            c = half(c);
            
            while (c != "0") {
                  if (largerOrEqual(a, b)) {
                        a = sub(a, b);
                        n = add(n, c);
                  }
                  b = half(b);
                  c = half(c);
            }
            return n;
      }
      
      function floatDiv(a, b, d) {
            return +div(mul(a, expon("10", d)), b) / expon("10", d);
      }
      
      function dbl(a) {
            return mul(a, "2");
      }
      
      function half(a) {
            var h = '';
            var charSet = '01234';
            var nextCharSet;
            for (var i = 0; i < a.length; i++) {
                  var digit = a[i];
                  if ('13579'.includes(digit)) {nextCharSet = '56789';}
                  else {nextCharSet = '01234';}
                  h += charSet.charAt(Math.floor(digit / 2));
                  charSet = nextCharSet;
            }
            h = h.replace(/\b0+/g, '');
            return h === "" ? "0" : h;
      }
      
      function larger(a, b) {
             if (a.length > b.length) return true;
             if (a.length < b.length) return false;
             return a>b;
      }
      
      function largerOrEqual(a, b) {
            return larger(a, b) || (a == b);
      }
      
      function smaller(a, b) {
             if (a.length < b.length) return true;
             if (a.length > b.length) return false;
             return a<b;
      }
      
      function smallerOrEqual(a, b) {
            return smaller(a, b) || (a == b);
      }
      
      function mod(a, b) {
            if(smaller(a, b)) return a;
            var quotient = div(a, b);
            return sub(a, mul(b, quotient));
      }
      
      function gcd(a, b) {
            if (larger(a, b)) {
                  var c = a;
                  a = b;
                  b = c;
            }
            return a == "0" ? b : gcd(mod(b, a), a);
      }
      
      function expon(a, b) {
            var r = "1";
            for (var i = 0; i < b; i++) {
                  r = mul(r, a);
            }
            return r;
      }
      
      function flog2(s) { // floor of log2arithm, then exp2ed
            if (smaller(s, 1)) return "0";
            var value = "1";
            while (smallerOrEqual(value, s)) {
                  value = dbl(value);
            }
            return half(value);
      }
      
      /***************************
      * number theoretic methods *
      ***************************/
      
      property var primes32: ["the index of this function starts at 1", 
            2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97, 101, 103, 107, 109, 113, 127, 131];
      
      function modpow(b, x, m) {   
            var r = "1";
            while (larger(x, 0)) {
                  if ("13579".includes(x[x.length - 1])) r = mod(mul(r, b), m);
                  x = half(x);
                  b = mod(mul(b, b), m);
            }
            return r;
      }
      
      function primePos(a) {
            return primes32[a];
      }
      
      function primeCount(a) {
            var primes32 = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53, 59, 61, 67, 71, 73, 79, 83, 89, 97, 101, 103, 107, 109, 113, 127, 131];
            var i = 2;
            var x = 0;
            while (i <= a) {
                  if (i == primes32[x]) x++;
                  i++;
            }
            return x;
      }
      
      function primeFactors(n) {
            var factors = [];
            var divisor = "2";
            
            while (n != undefined && largerOrEqual(n, "2")) {
                  if (mod(n, divisor) == "0") {
                        factors.push(divisor);
                        n = div(n, divisor);
                  } else {
                        divisor = add(divisor, "1");
                  }
            }
            return factors;
      }
      
      /*****************
      * vector methods *
      *****************/
      
      function toVector(s, p) { // vector[0] = residue, aka the primes that didn't make it to the vector (53/12 = ["53/1", -2, -1, 0, .., 0], when p = 47)
            var str = s.split("/");
            var a = ["1/1"];
            for (var i = 0; i < primeCount(p); i++) {a.push(0);}
            var p1 = primeFactors(str[0]);
            var p2 = primeFactors(str[1]);
            for (var i = 0; i < p1.length; i++) {
                  if (p1[i] <= p) a[primeCount(p1[i])] += 1;
                  else a[0] = mul_r(a[0], p1[i]);
            }
            for (var i = 0; i < p2.length; i++) {
                  if (p2[i] <= p) a[primeCount(p2[i])] -= 1;
                  else a[0] = div_r(a[0], p2[i]);
            }
            return a;
      } 
}
