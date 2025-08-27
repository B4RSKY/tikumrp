$(function() {
    window.addEventListener('message', function(event) {
        var data = event.data   
        if(data.type == "killChicken" ) {
            $('body').show()
            $('.sections').show()
            startKill()
        }
        if(data.type == "chickenPackage") {
            resetPackage()
            $('body').show()
            $('.lastpage').show()
        }
        if(data.type == "chickenCut") {
            resetLine()
            $('body').show()
            $('.kopya4').show()
        }
    })
})

$(document).mousemove(function(e) {
    $(".collocationRighthandCleaver").css({
        left: e.pageX,
        top: e.pageY
    });
});

var alive = true
let currentChickenSound = undefined

function startKill() {
    alive = true
    chickenSound()
}

function chickenSound() {
    if(alive) {
        sound('chicken', true)
        setTimeout(function(){
            chickenSound()
        }, 8000);
    }
}

function cutHead() {
    $('.sections').hide()
    $('.area').show()
    snd.pause()
    sound('kill')
    alive = false
    setTimeout(function(){
        cutHeadDone()
      }, 2000);
}

function cutHeadDone() {
    $('body').hide()
    $('.sections').hide()
    $('.area').hide()
    $.post('https://tk_disnaker/cutHead', JSON.stringify({}));
}

$(document).mousemove(function(e) {
    $(".ImageRH").css({
        left: e.pageX,
        top: e.pageY
    });
});

$(document).mousemove(function(e) {
    $(".centerRHC").css({
        left: e.pageX,
        top: e.pageY
    });
});

function resetLine() {
    $('.line').attr('src', 'images/lines.png')

    $('.CenterLines2').hide()
    $('.CenterLines3').hide()
    $('.CenterLines4').hide()
}

function chickenLine(number) {
    if(number >= 4) {
        lineDone()
    }
    sound('kill')
    $('.CenterLines'+number).attr('src', 'images/lineSor.png')
    number++
    $('.CenterLines'+number).show()
}

function lineDone() {
    $('body').hide()
    $('.kopya4').hide()
    $.post('https://tk_disnaker/lineDone', JSON.stringify({}));
}

let lastPart = undefined
var lastImage = undefined
function selectPart(number, image) {
    if(!lastPart) {
        $('.part_'+number).addClass('follow')
        lastPart = number
        lastImage = image
    }
}

$(document).mousemove(function(e) {
    $(".follow").css({
        left: e.pageX,
        top: e.pageY
    });
    lastElement = e
});

var partNumber = 0

function putPart() {
    if(lastPart) {
        div = `<img class="packagePart part`+lastPart+` packagePart`+lastPart+`" src="images/`+lastImage+`.png">`
        $('.partArea').append(div)
        $('.part_'+lastPart).remove()
        lastPart = undefined
        sound('meat')
        partNumber++
    }
    if(partNumber >= 5) {
        packageDone()
    }
}

function packageDone() {
    $('body').hide()
    $('.lastpage').hide()
    $.post('https://tk_disnaker/packageDone', JSON.stringify({}));
}

var partId = 0

function resetPackage() {
    partNumber = 0
    lastPart = undefined
    lastImage = undefined
    
    $('.packagePart').remove()
    $('.partChicken').remove()

    let div = `<img onclick="selectPart(1, 'meat')" class="part_1 partChicken" src="images/meat.png">
    <img onclick="selectPart(2, 'wingmeat')" class="part_2 partChicken" src="images/wingmeat.png">
    <img onclick="selectPart(3, 'wingmeat')" class="part_3 partChicken" src="images/wingmeat.png">
    <img onclick="selectPart(4, 'thigh')" class="part_4 partChicken" src="images/thigh.png">
    <img onclick="selectPart(5, 'thigh')" class="part_5 partChicken" src="images/thigh.png">`

    $('.lastpage').append(div)
}

function sound(a, chicken) {
    snd = new Audio("sound/"+a+".wav"); // buffers automatically when created
    snd.play();
}


// setTimeout(function(){
//     startKill()
// }, 1000);