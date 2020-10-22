import { pg } from '../connections/connect-postgres';
import { Post, SpaceId, WhoAndWhen} from '@subsocial/types/substrate/interfaces/subsocial';
import { resolveCidOfContent } from '@subsocial/api/utils';
import { postFields } from '../sql/TablesFields';
import { substrate } from '../substrate/subscribe';
import { upsertSpace } from './upsert-space';

export const upsertPostOrComment = async (post: Post) => {
	const { id, created } = post
	const updated: WhoAndWhen | undefined = post.updated.unwrapOr(undefined)
	const space_id = post.space_id.unwrapOr(undefined)
	const content = resolveCidOfContent(post.content)
	const shared_post_id = post.extension.isSharedPost ? post.extension.asSharedPost : null
	const comment = post.extension.isComment ? post.extension.asComment : null
	const parent_id_unwrapd = comment?.parent_id.unwrapOr(undefined)
	const root_post_id = comment?.root_post_id

	const params = [
		id.toNumber(),
		created.account.toString(),
		created.block.toNumber(),
		created.time.toNumber(),
		updated?.account.toString(),
		updated?.block.toNumber(),
		updated?.time.toNumber(),
		post.owner.toString(),
		shared_post_id?.toNumber(),
		parent_id_unwrapd?.toNumber(),
		root_post_id?.toNumber(),
		space_id?.toNumber(),
		content,
		post.extension.type,
		post.hidden.valueOf(),
		post.replies_count.toNumber(),
		post.hidden_replies_count.toNumber(),
		post.shares_count.toNumber(),
		post.upvotes_count.toNumber(),
		post.downvotes_count.toNumber(),
		post.score.toNumber()
	]

	const paramsJoined = params.map((_, i) => `$${i + 1}`).join(', ')
	const paramsForUpdate = postFields.map((value, i) => `${value} = $${i + 1}`).join(', ')

        
    const query = `
			INSERT INTO df.posts
				VALUES(${paramsJoined})
				ON CONFLICT (id) DO UPDATE SET
					${paramsForUpdate}`;

	try {
		await pg.query(query, params)
	}
	catch {
		if (space_id !== undefined) {
			const space =	await substrate.findSpace({id: space_id as SpaceId})
			await upsertSpace(space)
		}
		else if(root_post_id !== undefined) {
			const post = await substrate.findPost({id: root_post_id})
			await upsertPostOrComment(post)
		}
		await pg.query(query, params)
	}
}