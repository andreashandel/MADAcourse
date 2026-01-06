<script>

/* definition of content for the buttons */
const webex_buttons = {check_hidden:          "<b>&check;</b>",
                       check_hidden_alt:      "Check answer",
                       check_shown:           "<b>&lsh;</b>",
                       check_shown_alt:       "Hide check",
                       check_of_total:        "/",
                       solution:              "<b>&quest;</b>",
                       solution_alt:          "Correct solution",
                       question_next:         "<b>&#8634;</b>",
                       question_next_alt:     "Next question",
                       question_previous:     "",
                       question_previous_alt: ""}


/* update total correct if #webex-total_correct exists */
update_total_correct = function() {
  console.log("webex: update total_correct");

  document.querySelectorAll(".webex-total_correct").forEach(total => {
    p = total.closest(".webex-box");
    var correct = p.getElementsByClassName("webex-correct").length;
    var solvemes = p.getElementsByClassName("webex-solveme").length;
    var radiogroups = p.getElementsByClassName("webex-radiogroup").length;
    var selects = p.getElementsByClassName("webex-select").length;
    /* no specific class on input node, thus searching via query selector */
    var checkboxgroups = p.querySelectorAll("div[class=webex-checkboxgroup] input[type=checkbox]").length

    /* show number of correct / total number of answers */
    total.innerHTML = correct + "&nbsp;" + webex_buttons.check_of_total + "&nbsp;" + (solvemes + radiogroups + checkboxgroups + selects);
  });
}

/* check answers */
check_func = function() {
  console.log("webex: check answer");

  //var cl = elem.parentElement.classList;
  var cl = this.closest(".webex-box").classList;
  if (cl.contains("unchecked")) {
    cl.remove("unchecked");
    this.innerHTML = webex_buttons.check_shown; //"Hide check";
    if (webex_buttons.check_shown_alt.length > 0) this.setAttribute("title", webex_buttons.check_shown_alt);
  } else {
    cl.add("unchecked");
    this.innerHTML = webex_buttons.check_hidden; //"Check answer";
    if (webex_buttons.check_hidden_alt.length > 0) this.setAttribute("title", webex_buttons.check_hidden_alt);
  }
}

/* helper functions for checking the webex ID */
const id_checker = {"fmt": new RegExp("[g-zG-Z]"),
                    "load": function(e) { return e.getAttribute("id").match("(?<=(-)).*$")[0]; },
                    "eval": new TextEncoder(),
                    "dval": new TextDecoder()}

/* Show/hide correct solution */
solution_func = function() {
  console.log("webex: show/hide solution");

  var div = this.closest(".webex-question").querySelector(".webex-solution");
  var cl = div.classList;

  if (cl.contains("visible")) {
    cl.remove("visible");
  } else {
    cl.add("visible");
  }
}

/* function to check if the real answer is numeric */
convert_to_numeric = function(x) {
  if (typeof x == "string") {
    /* do nothing */
  } else if (x.length == 1) {
    /* take first element */
    x = x[0]
  } else {
    return NaN;
  }

  /* remove spaces for easier parsing */
  x = x.replace(/\s/g, "");

  /* Define patterns for different formats, note that spaces have been removed above */
  const patterns = [
    {regex: /^[+-]?\d+(\.\d{3})*,\d+$/, decimal: ",", thousand: "." },  // Format: "1.100.100.100,3"
    {regex: /^[+-]?\d+(,\d{3})*\.\d+$/, decimal: ".", thousand: "," },  // Format: "1,100,100,100.3"
    {regex: /^[+-]?\d+(\.|\.\d+)?$/, decimal: "." },                    // Format: "1100100100.5" or "1100100100."
    {regex: /^[+-]?\d+(,|,\d+)$/, decimal: "," }                        // Format: "1100100100,5" or "1100100100,"
  ];


  /* testing all regular expressions, convert to float if possible */
  for (const { regex, decimal, thousand } of patterns) {
    if (regex.test(x)) {
      let numeric = x;
      if (thousand) numeric = numeric.replace(new RegExp(`\\${thousand}`, "g"), "");
      numeric = numeric.replace(decimal, ".");
      return parseFloat(numeric);
    }
  }

  /* input of length 1 but none of the known formats, return NaN */
  return NaN;
}

/* Checking webex ID, returns formalsol */
check_id = function(e) {
  /* loading webex ID */
  var id = id_checker["load"](e);

  /* extracting answer */
  let answer = e.dataset.answer;

  /* checking unique id, prepare and return array */
  if (!id_checker["fmt"].test(id)) {
    const a = id_checker["eval"].encode(atob(answer));
    const b = id_checker["eval"].encode(id);
    const res = a.map((byte, index) => byte^b[index % b.length]);
    answer = id_checker["dval"].decode(res);
    /* Replacing &amp; with ' before parsing */
    answer = answer.replaceAll("&apos;", "'");
  }

  return JSON.parse(answer);
}

/* function for checking solveme answers */
solveme_func = function(e) {
  /* avoid that keyup and keychange twice execute this function within nms = 10
   * ms, clearing inputTimer and add timeout */
  console.log("webex: check solveme");

  /* float, precision for checking numeric answers */
  const eps = 0.00000000000001;

  /* get last checked user answer */
  const question = this.closest(".webex-question")

  /* extracting classes */
  var cl = this.classList;
  var my_answer = this.value;

  /* extracting classes */
  var cl = this.classList;

  /* empty answer? Job done */
  if (my_answer == "") {
    cl.remove("webex-correct");
    cl.remove("webex-incorrect");
    return false;
  }

  /* Find closest (parent) webex-question */
  let formalsols = check_id(this)

  /* by default we assume the users' answer is incorrect */
  var user_answer_correct = false;

  /* check if the correct answer is numeric, i.e. if 
   * formalsols is of length 1 containing one single numeric
   * value in a known format, else, NaN is returned */
  const num_formalsol = convert_to_numeric(formalsols);
  const num_my_answer = convert_to_numeric(my_answer);

  /* if the correct answer is numeric (float), the user's answer
   * must also be numeric. If not, it is wrong. Else we can
   * compare floating point numbers */
  if (!isNaN(num_formalsol) && !isNaN(num_my_answer)) {
    /* check if the real answer and the user input are numerically the same;
     * adding 'delta' to avoid precision issues */
    var diff = Math.abs(num_formalsol - num_my_answer);
    if (diff < parseFloat(this.dataset.tol) + eps) { user_answer_correct = true; }

  /* if the question contains regex, a regular expression is used
   * to evaluate the users answer. Allows for multiple regular expressions */
  } else if (cl.contains("regex")) {
    for (let i = 0; i < formalsols.length; i++) {
        let regex = new RegExp(formalsols[i], cl.contains("ignorecase") ? "i" : "");
        if (regex.test(my_answer)) { user_answer_correct = true; break; }
    }

  /* else we evaluate on 'string level', considering the creators preferences
   * regarding set options */
  } else {
    /* modify/prepare answer */
    if (cl.contains("ignorecase")) { my_answer = my_answer.toLowerCase(); }
    if (cl.contains("nospaces"))   { my_answer = my_answer.replace(/ /g, ""); }

    /* if the real answer includes user input - correct */
    if (formalsols.includes(my_answer)) {
      user_answer_correct = true;
  
      // added regex bit
      if (cl.contains("regex")) {
        answer_regex = RegExp(formalsols.join("|"))
        if (answer_regex.test(my_answer)) {
          cl.add("webex-correct");
        }
      }
    }
  }

  if (user_answer_correct) {
      cl.add("webex-correct");
      cl.remove("webex-incorrect");
  } else {
      cl.add("webex-incorrect");
      cl.remove("webex-correct");
  }

  update_total_correct();

}

/* function for checking select answers */
select_func = function(e) {
  console.log("webex: check select");

  var options   = [];
  Array.from(this.querySelectorAll("option")).forEach((option, index) => {
    if (!option.hasAttribute("value") || !option.getAttribute("value") === "blank") {
      options.push(option);
    }
  });

  /* get selected option */
  function get_selected(options) { return options.findIndex(option => option.selected); }
  var option_index = get_selected(options)

  /* loading webex ID */
  var formalsol = check_id(this)

  /* add class for current selection */
  this.classList.remove("webex-incorrect");
  this.classList.remove("webex-correct");
  if (option_index >= 0) {
    this.classList.add(formalsol[option_index] === 1 ? "webex-correct" : "webex-incorrect");
  }

  update_total_correct();
}

/* function for checking radiogroups answers */
radiogroups_func = function(e) {
  console.log("webex: check radiogroups");

  /* get real answer (binary integer array) */
  var id = e.target.getAttribute("name");
  var group = document.querySelector(".webex-radiogroup[id='webex-" + id + "']");
  var formalsol = check_id(group)

  /* check which radiobuttion is selected (user answer) */
  function get_checked(radios) {
    return radios.findIndex(radios => radios.checked);
  }
  var radios = Array.from(group.querySelectorAll("input[type='radio']"))
  var radio_index = get_checked(radios);

  /* remove existing classes */
  radios.forEach(radio => {
    let cl = radio.closest("label").classList
    cl.remove("webex-incorrect");
    cl.remove("webex-correct");
  });

  /* add class for current selection */
  let cl = radios[radio_index].closest("label").classList
  if (formalsol[radio_index] === 1) {
      cl.add("webex-correct");
  } else {
      cl.add("webex-incorrect");
  }

  update_total_correct();
}


/* function for checking checkboxgroups answers */
checkboxgroups_func = function(e) {
  console.log("webex: check checkboxgroups");

  /* get real answer (binary integer array) */
  var group = document.querySelector(".webex-checkboxgroup[id='" + this.id + "']");
  var formalsol = check_id(group);

  /* check which checkbox is checked (user answer) */
  function get_checked(group) {
      const checkboxes = Array.from(group.querySelectorAll("input[type='checkbox']"));
      return checkboxes.reduce((indices, checkbox, index) => {
          if (checkbox.checked) indices.push(index);
          return indices;
      }, []);
  }
  var checks = Array.from(group.querySelectorAll("input[type='checkbox']"));
  var check_index = get_checked(group);

  checks.forEach((e, index) => {
    var label = e.parentNode;
    var ans = formalsol[index];
    if ((e.checked && ans === 1) || (!e.checked && ans === 0)) {
        label.setAttribute("class", "webex-correct")
    } else {
        label.setAttribute("class", "webex-incorrect")
    }
  });

  update_total_correct();
}

/* shuffling array (thanks to stack overflow)
 * If argument x is an integer we create an integer sequence
 * from 0, 1, ..., (x - 1) and return a shuffled version. If
 * the input is an array, we simply shuffle it */
shuffle_array = function(x) {
   if (Number.isInteger(x) && !isNaN(x)) {
     x = Array.from({length: x}, (v, i) => i);
   }
   let shuffled = x.map(value => ({ value, sort: Math.random() }))
        .sort((a, b) => a.sort - b.sort).map(({ value }) => value)
   return shuffled;
}

/* ---------------------------------------------------------
 * ---------------------------------------------------------
 * --------------------------------------------------------- */
window.onload = function() {
  //console.log("webex: onload");

  /* setting up buttons and actions to show/hide answers */
  document.querySelectorAll(".webex-check").forEach(section => {
    section.classList.add("unchecked");

    /* ul to take up the list items with buttons */
    let button_ul = document.createElement("ul");
    button_ul.setAttribute("class", "webex-button-list");
    section.appendChild(button_ul);

    /* button to _check_ if answers given are correct */
    let li_check = document.createElement("li");
    button_ul.appendChild(li_check); /* add list item to ul */
    let btn_check = document.createElement("button");
    btn_check.innerHTML = webex_buttons.check_hidden;  // "Check answer";
    btn_check.setAttribute("class", "webex-button webex-button-check");
    if (webex_buttons.check_hidden_alt.length > 0) btn_check.setAttribute("title", webex_buttons.check_hidden_alt);
    btn_check.onclick = check_func;
    li_check.appendChild(btn_check);

    /* span to show current number of points (when _check_ active) */
    let spn = document.createElement("span");
    spn.classList.add("webex-total_correct");
    li_check.appendChild(spn);

    /* button to show the _solution_ if there is one */
    var has_solution = section.parentNode.querySelectorAll(".webex-solution").length > 0;
    if (has_solution) {
      let li_solution = document.createElement("li");
      button_ul.appendChild(li_solution); /* add list item to ul */
      let btn_solution = document.createElement("button");
      btn_solution.innerHTML = webex_buttons.solution; // "Correct answer";
      btn_solution.setAttribute("class", "webex-button webex-button-solution");
      if (webex_buttons.solution_alt.length > 0) btn_solution.setAttribute("title", webex_buttons.solution_alt);
      btn_solution.onclick = solution_func;
      li_solution.appendChild(btn_solution);
    }

  });

  /* set up webex-solveme inputs */
  document.querySelectorAll(".webex-solveme").forEach(solveme => {
    solveme.setAttribute("autocomplete","off");
    solveme.setAttribute("autocorrect", "off");
    solveme.setAttribute("autocapitalize", "off");
    solveme.setAttribute("spellcheck", "false");
    solveme.value = "";

    /* adjust answer for 'no spaces' (ignore spaces) */
    if (solveme.classList.contains("nospaces")) {
      solveme.dataset.answer = solveme.dataset.answer.replace(/ /g, "");
    }

    /* attach checking function, triggered on key up, change, and when
     * elemnt is out of focus. Only evaluated once by tracking changes
     * via variable solveme_last_user_answer */
    solveme.addEventListener("keyup",  solveme_func);
    solveme.addEventListener("change", solveme_func);
    solveme.addEventListener("blur",   solveme_func);

    /* adding span to show correct/incorrect icon */
    solveme.insertAdjacentHTML("afterend", " <span class='webex-icon'></span>")
  });

  /* set up radiogroups (single choice questions with display = "buttons") */
  document.querySelectorAll(".webex-radiogroup").forEach(radiogroup => {
    radiogroup.onchange = radiogroups_func;
  });

  /* set up checkboxgroups (multiple choice questions with display = "buttons") */
  document.querySelectorAll(".webex-checkboxgroup").forEach(checkboxgroup => {
    checkboxgroup.onchange = checkboxgroups_func;
  });

  /* set up selects (dropdown menus) */
  document.querySelectorAll(".webex-select").forEach(select => {
    select.onchange = select_func;
    /* append webex-icon for correct/incorrect icons */
    var elem = document.createElement("span")
    elem.classList.add("webex-icon")
    select.parentNode.appendChild(elem)
  });

  /* change to next/previous question if multiple are available */
  function handleQuestionClick(group, questions, step) {
    return async function() {
      /* get question order as integer vector */
      let questionOrder = group.dataset.questionOrder.split(",").map(str => parseInt(str));

      /* current question/position */
      let currentPosition = parseInt(group.dataset.currentPosition);

      /* Hide the current question */
      questions.forEach(question => { question.classList.remove("active"); });

      /* Move to the next question index */
      currentPosition = (currentPosition + step) % questionOrder.length;
      if (currentPosition < 0) currentPosition = currentPosition + questionOrder.length

      /* Display the new question */
      questions[questionOrder[currentPosition]].classList.add("active");

      // Update the currentPosition data attribute on the group div
      group.dataset.currentPosition = currentPosition;
    };
  }

  document.querySelectorAll(".webex-group").forEach(group => {
    const questions = Array.from(group.querySelectorAll(".webex-question"));

    /* Create vector with question order. If the webex-group does
     * not have class '.noshuffle' we will randomly shuffle the order */
    let questionOrder = Array.from({length: questions.length}, (v, i) => i);
    if (!group.classList.contains("noshuffle")) {
      questionOrder = shuffle_array(questionOrder);
    }

    /* take start position (if set) or start at 0 */
    const currentPosition = parseInt(group.getAttribute("data-start-position")) || 0;

    /* show the default question for each group */
    questions[questionOrder[currentPosition]].classList.add("active");

    /* store random order of questions as well as current position */
    group.dataset.questionOrder   = questionOrder;
    group.dataset.currentPosition = currentPosition;

    /* find all webex-questions, search for .webex-button-list and
     * populate the list with necessary <li><button>...</button></li> elements */
    questions.forEach(question => {
        let button_ul = question.querySelector("ul.webex-button-list");

        let li_next = document.createElement("li");
        let nextButton = document.createElement("button");
        nextButton.setAttribute("class", "webex-button webex-button-next");
        if (webex_buttons.question_next_alt.length > 0) nextButton.setAttribute("title", webex_buttons.question_next_alt);
        nextButton.innerHTML = webex_buttons.question_next; // "Next question";
        nextButton.addEventListener("click", handleQuestionClick(group, questions, 1));
        li_next.appendChild(nextButton);

        let li_previous = document.createElement("li");
        let previousButton = document.createElement("button");
        previousButton.setAttribute("class", "webex-button webex-button-previous");
        if (webex_buttons.question_previous_alt.length > 0) previousButton.setAttribute("title", webex_buttons.question_previous_alt);
        previousButton.innerHTML = webex_buttons.question_previous; // "Previous question";
        previousButton.addEventListener("click", handleQuestionClick(group, questions, -1));
        li_previous.appendChild(previousButton);

        if (webex_buttons.question_previous.length > 0) button_ul.appendChild(li_previous);
        if (webex_buttons.question_next.length > 0) button_ul.appendChild(li_next);
    });
  });

  /* Development options */
  document.querySelectorAll(".webex-question.check").forEach(question => {
      question.querySelector(".webex-button-check").click()
  });
  document.querySelectorAll(".webex-question.solution").forEach(question => {
      let btn = question.querySelector(".webex-button-solution");
      if (btn !== null) { btn.click(); }
  });

  /* Pre-filling <input> fields */
  document.querySelectorAll(".webex-question.prefill").forEach(question => {
      question.querySelectorAll("input.webex-solveme").forEach(solveme => {
          let x = JSON.parse(solveme.dataset.answer);
          solveme.value = x[0];
          /* Trigger the on change event */
          solveme.dispatchEvent(new Event("change"));
      });

      /* Pre-filling radiogroups, that is for schoice questions */
      question.querySelectorAll(".webex-radiogroup").forEach(radiogroup => {
          let x = JSON.parse(radiogroup.dataset.answer);
          let idx = x.indexOf(1);
          let radios = radiogroup.querySelectorAll('input[type="radio"]');
          radios[idx].checked = true;
          /* Trigger the on change event */
          radios[idx].dispatchEvent(new Event("change", { bubbles: true }));
      });

      /* Pre-filling checkboxgroups, that is for schoice questions w/ dropdown menus */
      question.querySelectorAll(".webex-select").forEach(dropdown => {
          let x = JSON.parse(dropdown.dataset.answer);
          let idx = x.indexOf(1) + 1; /* +1 to skip the first blank option */
          let options = dropdown.querySelectorAll("option");
          options[idx].selected = true;
          /* Trigger the on change event */
          options[idx].dispatchEvent(new Event("change", { bubbles: true }));
      });

      /* Pre-filling checkboxgroups, that is for mchoice questions */
      question.querySelectorAll(".webex-checkboxgroup").forEach(radiogroup => {
          let x = JSON.parse(radiogroup.dataset.answer);
          let checkboxes = radiogroup.querySelectorAll('input[type="checkbox"]');
          for (let i = 0; i < checkboxes.length; i++) {
              checkboxes[i].checked = x[i];
          }
          /* Trigger the on change event */
          checkboxes[0].dispatchEvent(new Event("change", { bubbles: true }));
      });
  });

  /* Show set tolerance (devel option) */
  function calc_width(x, txt, offset = 20) {
      /* We do the following:
       * Create a new span, insert the value we need in the .tolerance
       * input node, and calculate its offsetWidth. Then remove it
       * again; this is just used to calculate the required width. */
      var cwtmp = document.createElement("span");
      x.appendChild(cwtmp);
      cwtmp.innerHTML = txt || "";
      var w = parseInt(cwtmp.getBoundingClientRect().width) + offset;
      cwtmp.remove();
      return w;
  }

  /* If tolerance should be shown (devel option) we calculate:
   * - the width required to properly display the solution
   * - the width required to properly display the tolerance
   * - add a new element to display the tolerance
   * - reduce the width of the solution input box. */
  document.querySelectorAll(".webex-question.tolerance").forEach(question => {
      question.querySelectorAll("input[data-tol]").forEach(elem => {
          var w = null;

          /* Add new element showing the tolerance */
          let tol = document.createElement("input");
          tol.type = "text"; // <inpyt type="text">
          tol.disabled = true; // Disable input element
          tol.classList.add("tolerance"); // Appending class
          tol.value = "± " + elem.getAttribute("data-tol");

          /* Add new node */
          elem.parentNode.insertBefore(tol, elem)

          var body     = document.querySelector("body");
          //tol.value = "± " + "0.0000007";
          //tol.value = "± " + "0.07";
          w    = calc_width(body, tol.value);
          wold = parseInt(elem.getBoundingClientRect().width);
          wmin = calc_width(body, elem.value);

          /* Calculate required width of the 'tolerance' node, and the
           * reduction of the original 'input' node */
          let wnew = Math.max(wmin, wold - w);
          tol.style.width  = w + "px";
          elem.style.width = wnew + "px";
      });
  });

  update_total_correct();
}

</script>
