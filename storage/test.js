const filters = [{foo: 1}, undefined, {bar: 2}, {a: 3, b: 4}];
const reduced = filters.reduce((s, u) => Object.assign(s, u), {});
console.log(reduced);
