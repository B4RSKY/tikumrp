let allOptions = [];
let currentVehicleName = "UNKNOWN";
let currentSpawnCode = "UNKNOWN";

window.addEventListener("message", function (event) {
    if (event.data.action === "open") {
        allOptions = event.data.options;
        currentVehicleName = event.data.vehiclename || "UNKNOWN";
        currentSpawnCode = event.data.spawnCode || currentVehicleName;

        const searchInput = document.getElementById("searchInput");
        const keyword = searchInput.value.toLowerCase();
        const filtered = allOptions.filter(opt =>
            opt.label.toLowerCase().includes(keyword) ||
            opt.name.toLowerCase().includes(keyword) ||
            (opt.hint && opt.hint.toLowerCase().includes(keyword))
        );

        renderOptions(filtered);

        document.getElementById("vehiclename").textContent = `${currentSpawnCode}`;
        document.getElementById("container").style.display = "block";
    }
});

function renderOptions(options) {
    const form = document.getElementById("handlingForm");
    form.innerHTML = "";

    options.forEach(opt => {
        const wrapper = document.createElement("div");
        wrapper.classList.add("input-row");

        const label = document.createElement("label");
        label.textContent = opt.label;

        const input = document.createElement("input");
        input.type = "text";
        input.name = opt.name;
        input.value = opt.default;

        wrapper.appendChild(label);
        wrapper.appendChild(input);
        form.appendChild(wrapper);

        if (opt.hint) {
            const hint = document.createElement("small");
            hint.textContent = `➖ ${opt.hint}`;
            form.appendChild(hint);
        }
    });
}



function closeUI() {
    document.getElementById("container").style.display = "none";
    fetch("https://lex_handlingNUI/close", { method: "POST" });
}

document.getElementById("submitBtn").addEventListener("click", function () {
    const data = {};
    const inputs = document.querySelectorAll("#handlingForm input");
    inputs.forEach(input => {
        data[input.name] = input.value;
    });

    fetch("https://lex_handlingNUI/submit", {
        method: "POST",
        headers: {
            "Content-Type": "application/json",
        },
        body: JSON.stringify(data),
    });

    closeUI();
});

document.getElementById("cancelBtn").addEventListener("click", function () {
    closeUI();
});

document.getElementById("copyBtn").addEventListener("click", function () {
    const inputs = document.querySelectorAll("#handlingForm input");
    const inputMap = {};
    inputs.forEach(input => {
        inputMap[input.name] = input.value.trim();
    });

    const handlingName = currentSpawnCode;

    let output = `  <handlingName>${handlingName}</handlingName>\n`;

    inputs.forEach(input => {
        const name = input.name;
        const value = input.value.trim();

        if (name.startsWith("vec")) {
            const parts = value.split(",");
            const x = parseFloat(parts[0]) || 0;
            const y = parseFloat(parts[1]) || 0;
            const z = parseFloat(parts[2]) || 0;
            output += `  <${name} x="${x.toFixed(6)}" y="${y.toFixed(6)}" z="${z.toFixed(6)}" />\n`;
        } else if (name.startsWith("str") || name === "AIHandling") {
            output += `  <${name}>${value}</${name}>\n`;
        } else if (name.startsWith("n")) {
            const num = parseInt(value);
            output += `  <${name} value="${isNaN(num) ? 0 : num}" />\n`;
        } else {
            const num = parseFloat(value);
            output += `  <${name} value="${isNaN(num) ? 0 : num.toFixed(6)}" />\n`;
        }
    });

    const textarea = document.createElement("textarea");
    textarea.value = output;
    textarea.setAttribute("readonly", "");
    textarea.style.position = "absolute";
    textarea.style.left = "-9999px";
    document.body.appendChild(textarea);
    textarea.select();

    const successful = document.execCommand("copy");
    document.body.removeChild(textarea);

    if (successful) {
        // alert("Handling.meta berhasil disalin ke clipboard!");
    } else {
        // alert("Gagal menyalin ke clipboard.");
    }
});

document.getElementById("searchInput").addEventListener("input", function () {
    const keyword = this.value.toLowerCase();
    const filtered = allOptions.filter(opt =>
        opt.label.toLowerCase().includes(keyword) ||
        opt.name.toLowerCase().includes(keyword) ||
        (opt.hint && opt.hint.toLowerCase().includes(keyword))
    );
    renderOptions(filtered);
});

document.addEventListener("keydown", function (event) {
    if (event.key === "Escape" || event.keyCode === 27) {
        closeUI();
    }
});
