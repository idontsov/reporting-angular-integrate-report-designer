import { Selector } from 'testcafe';

fixture('Smoke Tests')
//    .page(configuration.pageUri)
    .beforeEach(async t => {
        await t.maximizeWindow();
    });

test('Open Designer', async t => {
    console.log('Open Designer TEST');
});

test('Display Report Preview', async t => {
    console.log('Display Report Preview TEST');
});
