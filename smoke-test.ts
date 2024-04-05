import { Selector } from 'testcafe';
import { assertUntilCondition, designerMenuButton, getMenuItemByText, getToolbarButtonByText } from '@devexpress/reporting-testcafe-helpers/units';
import { checkPreviewPage } from '@devexpress/reporting-testcafe-helpers/preview';

fixture('Smoke Tests')
    .beforeEach(async t => {
        await t.maximizeWindow();
    });

test('Report Designer', async t => {
    await assertUntilCondition(t, () => getToolbarButtonByText('preview').exists, 'Wait for designer loading');
    await t
        .dispatchEvent(getToolbarButtonByText('preview'), 'click');
    await checkPreviewPage(t, 15);
    await t
        .dispatchEvent(getToolbarButtonByText('design'), 'click')
        .click(designerMenuButton)
        .click(getMenuItemByText('Exit'));
});
