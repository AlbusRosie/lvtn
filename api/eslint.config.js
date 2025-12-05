const js = require('@eslint/js');

module.exports = [
    js.configs.recommended,
    {
        languageOptions: {
            ecmaVersion: 2022,
            sourceType: 'commonjs',
            globals: {
                ...require('globals').node,
            },
        },
        rules: {
            // Add any custom rules here if needed
        },
    },
];
