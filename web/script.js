const $body = $("body");
const ResourceName = GetParentResourceName();

class NuiModuleHandler {
	#modules = {};
    #activeModule;
    #loadingModules = {};
    currentLanguage = 'pt-BR';
    #onLanguageUpdateFunctions = [];

	constructor() {

        document.querySelector('body').innerHTML = ''

		messageListener.addHandler("RegisterInterface", (data) => {
            const { moduleName, nuiType } = data;

			try {
                this.#modules[moduleName] = { nuiType };
                let e = document.querySelector('#nui-' + moduleName)
                if (e) {
                    e.style.display = 'none'
                } else {
                    $body.append(`<div id="nui-${moduleName}" class="nui-type-${nuiType}"></div>`);
                }
                const nui = $(`#nui-${moduleName}`);
                this.#loadingModules[moduleName] = new Promise((resolve, reject) => {
                    nui.load(`../scripts/${moduleName}/web/index.html`, (data) => {
                        resolve(true)
                        this.#loadingModules[moduleName] = null
                    })
                });
                if (nuiType == 1) {
                    nui.fadeOut(0);
                }
            } catch (err) {
            }
		});

		messageListener.addHandler("OpenUI", async (info) => {
			const { moduleName } = info;
            const { nuiType, openFunc, openOptions } = this.#modules[moduleName];

            delete info.moduleName

            if (nuiType == 1) {
                if (this.#activeModule) {
                    throw new Error('A module is already opened')
                }
        
                if (this.#loadingModules[moduleName]) {
                    await this.#loadingModules[moduleName]
                }
        
                await this.#EnsureNuiLoad(moduleName);
                this.#activeModule = moduleName
        
                if (!openOptions.disableAutoShow) {
                    $(`#nui-${moduleName}`).fadeIn(1)
                }

                if (openOptions.hideUIsType3) {
                    $('.nui-type-3').fadeOut(1)
                }

            }

            if (openFunc && !info.ignoreOpenUIHandler) {
                openFunc(info.data);
            }

        });
        
        messageListener.addHandler("CloseUI", async (info) => {
			const { moduleName } = info;
            const { nuiType, openOptions, closeOptions, closeFunc } = this.#modules[moduleName];

            if (!closeOptions.disableAutoHide && nuiType == 1) {
                $('#nui-' + moduleName).fadeOut(0)
            }

            if (nuiType == 1) {
                
                if (openOptions.hideUIsType3) {
                    $('.nui-type-3').fadeIn(1)
                }

            }

            if (closeFunc && !info.ignoreClosenUIHandler) {
                closeFunc(info.data)
            }

            this.#activeModule = null
        });
        
        messageListener.addHandler('setLanguage', (data) => {
            this.#onLanguageUpdateFunctions.map(async (cb) => cb(this.currentLanguage, data.language) )
            this.currentLanguage = data.language;
        })

        messageListener.addHandler('RemoveInterface', (data) => {
            const { moduleName } = data;
            const nui = document.querySelector(`#nui-${moduleName}`);
            nui.remove()
        })

        window.onload = () => {
            FetchData(null, { }, null, 'nui-ready')
        }
	}

    async #EnsureNuiLoad(moduleName) {
        const nui = $("#nui-" + moduleName);
        if (nui.html() == "") {
            return await new Promise((resolve, reject) => {
                nui.load(`../scripts/${moduleName}/web/index.html`, () => {
                    resolve(true);
                });
            });
        }
    }

    onLanguageChange(cb) {
        this.#onLanguageUpdateFunctions.push(cb);
    }

	getRegisteredModules() {
		return this.#modules;
	}

	getActiveModule() {
		return this.#activeModule;
	}

	registerOpenUiFunction(moduleName, func, options) {
        if (this.#modules[moduleName]) {
            
            if (!options) options = { hideUIsType3: true }
            if ((options.hideUIsType3 === null) || (options.hideUIsType3 == undefined)) options.hideUIsType3 = true

            this.#modules[moduleName].openFunc = func;
            this.#modules[moduleName].openOptions = options;
		} else {
			throw new Error(`Module ${moduleName} is not registered`);
        }
	}

	registerCloseUiFunction(moduleName, func, options) {
		if (this.#modules[moduleName]) {
            this.#modules[moduleName].closeFunc = func;

            if (!options) options = {}

            this.#modules[moduleName].closeOptions = options
		} else {
			throw new Error(`Module ${moduleName} is not registered`);
        }

        if (this.#modules[moduleName].nuiType == 1) {
            
            keyPressListener.addHandler('Escape', moduleName, () => {
                const { nuiType, openOptions, closeOptions, closeFunc } = this.#modules[moduleName];
    
                if (!closeOptions.disableAutoHide) {
                    $('#nui-' + moduleName).fadeOut(0)
                }
                
                if (openOptions.hideUIsType3) {
                    $('.nui-type-3').fadeIn(1)
                }

                if (closeFunc) {
                    closeFunc()
                }
    
                this.#activeModule = null
    
            })

        }

	}

}

class MessageListener {
	#eventHandlers = {};

	constructor() {
		window.addEventListener("message", (event) => {
			if (!event || !event.data || !event.data.action) return;

            const func = this.#eventHandlers[event.data.action];
            
            delete event.data.action

			if (func) func(event.data);
		});
	}

	addHandler(actionName, func) {
		this.#eventHandlers[actionName] = func;
	}
}

class KeyPressListener {
    #keyHandlers = {};
    #disabledKeys = {};

	constructor() {
        document.onkeydown = (event) => {
			const activeModule = nuiModuleHandler.getActiveModule();
			if (
				activeModule &&
				this.#keyHandlers[activeModule] &&
                this.#keyHandlers[activeModule][event.key] &&
                !this.#disabledKeys[activeModule][event.key]
			) {
				this.#keyHandlers[activeModule][event.key].map(async (v, k) =>
					v()
				);
			}
		};
	}

	addHandler(key, moduleName, func) {
		if (!this.#keyHandlers[moduleName]) this.#keyHandlers[moduleName] = {};
        if (!this.#keyHandlers[moduleName][key]) {
			this.#keyHandlers[moduleName][key] = [];
            this.#disabledKeys[moduleName] = {}
        }
		this.#keyHandlers[moduleName][key].push(func);
    }
    
    disableKeyPress(key, moduleName) {
        this.#disabledKeys[moduleName][key] = true
    }

    enableKeyPress(key, moduleName) {
        this.#disabledKeys[moduleName][key] = false
    }
}

class Module {
    currentLanguage = 'pt-BR';
    moduleName;
    #messageHandlers = {};
    #moduleLanguage = {};
    lang = {};
    fetching = false;
    element;

    constructor(moduleName) {
        this.moduleName = moduleName
        this.element = document.getElementById('nui-'+this.moduleName)

        messageListener.addHandler(moduleName + '-sendMessage', (data) => {
            const { _action } = data;
            if (_action && this.#messageHandlers[_action]) {
                this.#messageHandlers[_action](data)
            }
        })

        const moduleElement = document.querySelector("#nui-" + this.moduleName)
        
        let self = this

        this.lang = new Proxy({}, {
            get(target, key, receiver) {
                return self.#moduleLanguage[key] || ''
            },
            set(target, key, value, receiver) {
                return false
            }
        })

        let updating = true

        function updateElements() {
            updating = true
            for (const element of moduleElement.querySelectorAll("*[lang]")) {
                const elLang = element.getAttribute('lang')
                if (element.nodeName == 'INPUT') element.placeholder = self.lang[elLang]
                else element.innerHTML = self.lang[elLang]    
                element.setAttribute('set-lang', nuiModuleHandler.currentLanguage)
            }
            updating = false
        }

        function setLang(lang) {
            self.currentLanguage = lang
            fetch('https://cfx-nui-nyo_lib/scripts/' + self.moduleName + '/lang/' + lang + '.json').then(res => res.text().then(async text => {
                self.#moduleLanguage = await JSON.parse(text || '{}')
                updateElements()
            }))
        }

        setLang(nuiModuleHandler.currentLanguage)

        nuiModuleHandler.onLanguageChange((oldLanguage, newLanguage) => setLang(newLanguage))
        moduleElement.addEventListener('DOMSubtreeModified',() => !updating && updateElements())

    }

    registerOpenUiFunction(func, options) {
        return nuiModuleHandler.registerOpenUiFunction(this.moduleName, func, options)
    }

    registerCloseUiFunction(func, options) {
        return nuiModuleHandler.registerCloseUiFunction(this.moduleName, func, options)
    }

    addMessageHandler(action, func) {
        if (!this.#messageHandlers[action]) {
            this.#messageHandlers[action] = func
        }
    }

    addKeyPressHandler(key, func) {
        keyPressListener.addHandler(key, this.moduleName, func)
    }

    disableKeyPress(key) {
        keyPressListener.disableKeyPress(key, this.moduleName)
    }

    enableKeyPress(key) {
        keyPressListener.enableKeyPress(key, this.moduleName)
    }

    async fetch(url, data, cb, preventMultipleFetching) {
        if (preventMultipleFetching && this.fetching) {
            if (cb) cb(false)
            return false
        }
        this.fetching = true
        const res = await FetchData(null, data, null, this.moduleName + '/' + url)
        this.fetching = false
        if (cb) cb(res)
        else return res
    }

}

async function FetchData(url, data, cb, path) {
	const res = await fetch(`https://nyo_lib/${path ? path : nuiModuleHandler.getActiveModule() + '/' + url}`, {
		method: "POST",
		headers: {
			"Content-Type": "application/json; charset=UTF-8",
		},
		body: typeof data === "object" ? JSON.stringify(data) : null,
    });
    if (res.headers.get('Content-Type') == 'application/json') {
        const response = await res.json();
        if (cb) cb(response);
        else return response;
    } else {
        const response = await res.text();
        if (cb) cb(response);
        else return response;
    }
}

function ParseItemImage(itemIndex) {
    return itemIndex.replace('wbody|', '').replace('wammo|', 'mun-');
}

const messageListener = new MessageListener();
const keyPressListener = new KeyPressListener();
const nuiModuleHandler = new NuiModuleHandler();
