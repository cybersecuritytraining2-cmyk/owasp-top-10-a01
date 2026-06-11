/** @type {import('tailwindcss').Config} */
export default {
  content: ["./index.html", "./src/**/*.{vue,js}"],
  theme: {
    extend: {
      colors: {
        ink: "#0a1020", // page background
        slab: "#101a31", // header / footer
        card: "#142039", // panels
        card2: "#1a2748", // raised elements
        line: "#27375c", // borders
        text: "#eaf0fb", // primary text
        sub: "#9fb0d0", // secondary text
        brand: "#3f7dff", // Vault Street blue
        "brand-dark": "#2f63d6",
        pos: "#3ecf8e", // money in
        neg: "#f0617a", // money out
        gold: "#f2c14e", // accent / warnings
      },
      fontFamily: {
        sans: ["Inter", "system-ui", "sans-serif"],
        mono: ["ui-monospace", "SFMono-Regular", "Menlo", "monospace"],
      },
    },
  },
  plugins: [],
};
