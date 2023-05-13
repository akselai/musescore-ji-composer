import QtQuick 2.2 // TODO : HEJI note name support
import MuseScore 3.0 // TODO : convert note with accidental to note with TEXT accidental
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.3
import QtQuick.Layouts 1.1
import QtQuick.Dialogs 1.1
import "file:///home/akselai/Documents/MuseScore3/Plugins/calc.js" as Calc

MuseScore {
    menuPath: "Plugins.ji_composer"
    description: "A control panel for composing in just intonation (JI)."
    version: "1.0"
    requiresScore: false
    pluginType: "dialog"
    dockArea: "left"
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
                                if (baseNote(notes[k - 1]) != baseNote(note) || baseOctave(notes[k - 1]) != baseOctave(note)) {
                                    console.log(k);
                                }
                            }
                        }
                        for (var k = 0; k < notes.length; k++) {
                            /*
                            if (curlen != 0) {
                                  var commaList = cursor.segment.annotations[0].text.split("\n");
                                  func(note, commaList[commaList.length - k - 1]);
                            } else {
                                  func(note, "*");
                            }
                            */
                            func(note, "*");
                        }
                    }
                    pointer++;
                    cursor.next();
                }
            }
        }
    }

    function getNote(object) {
        var acx = object.accidentalType + 0;
        var acc = 0;
        switch (acx) {
            case 0: acc = 0; break; // nothing
            case 1: acc = -1; break; // b
            case 2: acc = 0; break; // natural
            case 3: acc = 1; break; // #
            case 4: acc = 2; break; // ##
            case 5: acc = -2; break; // bb
            case 6: acc = 3; break; // ###
            case 7: acc = -3; break; // bbb
            default: acc = 0;
        }
        var midiNum = (object.pitch - acc) % 12;
        var nm = "";
        switch (midiNum) {
            case 9: nm = "A"; break;
            case 11: nm = "B"; break;
            case 0: nm = "C"; break;
            case 2: nm = "D"; break;
            case 4: nm = "E"; break;
            case 5: nm = "F"; break;
            case 7: nm = "G"; break;
            default: console.log(midiNum + " cannot get name! " + acc);
        }
        return {name: nm, accidental: acc, octave: Math.floor((object.pitch - acc) / 12) - 1};
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
        var text = newElement(Element.STAFF_TEXT);
        text.placement = Placement.ABOVE;
        text.text = mul_r(noteNameInterval(baseNote(x)), pow_r("2187/2048", val));
        c.add(text);

        x.fixed = true;
        x.fixedLine = 100; //noteToLine(x);
        x.accidentalType = valAccidental(val);
        console.log("a237468 " + x.fixedLine);
        /*
        var txt = newElement(Element.STAFF_TEXT);
        txt.placement = Placement.ABOVE;
        txt.text = '<font face="atesting"/>' + '<font size="20"/>' + "333___";
        txt.offsetY = 2;
        txt.offsetX = -1;
        c.add(txt);
        */
    }


    function noteTick(note) {
        var esc = 0;
        while (note.type != Element.SEGMENT) {
            note = note.parent;
            if (note.tick >= 0) {
                console.log(note.tick);
                return note.tick
            };
            esc++;
            if (esc > 6) {
                return undefined;
            }
        }
    }
	
	function addNoteAfter(pitch, tuning, fixedLine, accidental, tick, dur_z, dur_n) {
        var c = curScore.newCursor();
        c.track = 0;
        c.rewindToTick(tick);
		console.log("ok");
        c.next();
        if (dur_z !== undefined && dur_n !== undefined) {
            c.setDuration(dur_z, dur_n);
        } else {
            c.setDuration(1, 4);
        }
		c.addNote(pitch);
        c.prev();
		var x = c.element.notes[0];
		
		x.fixed = true;
        x.fixedLine = fixedLine;
		
		x.tuning = tuning;
		
        var txt = newElement(Element.STAFF_TEXT);
        txt.placement = Placement.ABOVE;
        txt.text = '<font face="atesting"/>' + '<font size="20"/>' + accidental;
        txt.offsetY = 2;
        txt.offsetX = -1;
        c.add(txt);
	}

    onRun: {
    atest();
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
            onClicked: {
                applyToNotesInSelection(tune, true);
            }
        }
/*
        Button {
            text: "m3"
            Layout.columnSpan: 1
            Layout.fillWidth: false
            onClicked: {
     		    curScore.startCmd();
                addNoteAfter(60, 50, 0, null, noteTick(curScore.selection.elements[0]), 1, 4);
				curScore.endCmd();
            }
        }
	*/
		
		
		Button {
            text: "m3"
            Layout.columnSpan: 1
            Layout.fillWidth: false
            onClicked: {
                stepper("m3");
            }
        }
/*
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
		*/
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
    
    function atest() {
        curScore.startCmd();
        console.log(getNote(curScore.selection.elements[0]).name);
    }

    function stepper(interval) {
        curScore.startCmd();
        intervalStep(noteTick(curScore.selection.elements[0]), interval, 1, 4);

        applyToNotesInSelection(tune, true);
        curScore.endCmd();
    }}
