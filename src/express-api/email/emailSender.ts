import { createTransport, getTestMessageUrl } from 'nodemailer'
import { emailHost, emailPort, emailUser, emailPassword } from '../../env';
import { newLogger } from '@subsocial/utils';
import { ActivityType } from './utils';
import { NotificationTemplateProp, ConfirmationLink } from './notifications';
import { readFileSync } from 'fs';
import { join } from 'path';
import { compile, registerHelper } from 'handlebars';
import { FeedTemplateProp } from './feed';

const log = newLogger('Email')

type DataTemplateProp = NotificationTemplateProp[] | FeedTemplateProp[] | ConfirmationLink

export const sendEmail = async (email: string, data: DataTemplateProp, type: ActivityType) => {
	const transporter = createTransport({
		host: emailHost,
		port: parseInt(emailPort),
		secure: true, auth: {
			user: emailUser,
			pass: emailPassword,
		},
	});
	var source = readFileSync(join(__dirname, `templates/${type}/html.hbs`), 'utf8');

	registerHelper('notEq', function (v1, v2, options) {
		if (v1 !== v2) {
			return options.fn(this);
		}
		return options.inverse(this);
	});
	const template = compile(source)

	const info = await transporter.sendMail({
		from: emailUser,
		to: email,
		subject: `New ${type}`,
		html: template({ data })
	})
	log.debug("Message sent: %s", info.messageId);

	log.debug("Preview URL: %s", getTestMessageUrl(info));
}