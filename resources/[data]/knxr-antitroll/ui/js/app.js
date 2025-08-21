function main() {
    return {
        show: false,
        jamLeft: 24,
        minleft: 60,
        
        listen() {
            window.addEventListener('message', (event) => {
                let data = event.data

                switch(data.type) {
                    case 'show':
                        this.show = data.show;
                        break;

                    case 'update':
                        this.jamLeft = data.jamLeft;
                        this.minleft = data.minleft;
                        break;
                }
            })
        }
    }
}