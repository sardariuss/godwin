module.exports = {
	content: ["./index.html", "./src/**/*.{vue,js,ts,jsx,tsx}"],
	theme: {
		fontFamily: {
			inter: "'Inter', sans-serif",
			ultra: "'Ultra', sans-serif",
			archivo_black: "'Archivo Black', sans-serif",
		},
		extend: {
			minHeight: {
				'half-screen': '50vh',
			},
			spacing: {
				'18': '76px',
        '160': '40rem',
      },
			width: {
        '4/5-screen': '80vw;',
      },
			padding:{
				'1/3' : '33.3333333%',
			},
			height: {
        '128': '32rem',
      },
			colors: {
        'google-blue': '#4285F4',
				'google-red': "#DB4437",
				'google-yellow': "#F4B400",
				'google-green': "#0F9D58",
				'slate-850' : '#172032'
      },
			transitionDuration: {
				'2000': '2000ms',
			},
			scale: {
				'-100': '-1',
			},
			gridTemplateColumns: {
        // Simple 14 column grid
        '14': 'repeat(14, minmax(0, 1fr))',
      }
		},
	},
	plugins: [],
	darkMode: 'class',
};
