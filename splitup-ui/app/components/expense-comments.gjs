import Component from '@glimmer/component';
import { tracked } from '@glimmer/tracking';
import { action } from '@ember/object';
import { service } from '@ember/service';
import { on } from '@ember/modifier';
import { fn, eq } from '@ember/helper';

export default class ExpenseCommentsComponent extends Component {
  @service api;
  @service auth;
  @service router;
  @service toast;

  @tracked commentText = '';
  @tracked commentError = null;
  @tracked isSubmitting = false;
  @tracked isDeletingCommentId = null;

  get comments() {
    return this.args.comments ?? [];
  }

  get hasComments() {
    return this.comments.length > 0;
  }

  get displayComments() {
    return this.comments.map((comment) => ({
      ...comment,
      formattedDate: this.formatCommentDate(comment),
      canDelete: this.canDeleteComment(comment),
    }));
  }

  get canAddComments() {
    return Boolean(this.auth.isAuthenticated);
  }

  canDeleteComment(comment) {
    return String(comment?.addedByEmail) === String(this.auth.userEmail);
  }

  formatCommentDate(comment) {
    if (!comment?.createdAt) {
      return '';
    }
    return new Date(comment.createdAt).toLocaleString('en-US', {
      month: 'short',
      day: 'numeric',
      hour: 'numeric',
      minute: '2-digit',
    });
  }

  @action updateCommentText(event) {
    this.commentText = event.target.value;
  }

  @action async submitComment(event) {
    event.preventDefault();
    const content = this.commentText.trim();
    if (!content) {
      this.commentError = 'Comment content is required';
      return;
    }

    this.commentError = null;
    this.isSubmitting = true;
    try {
      const response = await this.api.post(`/api/v1/expense/${this.args.expenseId}/comments`, {
        content,
      });
      if (response?.code !== 0) {
        throw new Error(response?.error ?? 'Failed to add comment');
      }
      this.commentText = '';
      this.toast?.success('Comment added');
      this.router.refresh('expenses.expense');
    } catch (error) {
      this.commentError = error.message;
    } finally {
      this.isSubmitting = false;
    }
  }

  @action async deleteComment(commentId) {
    if (!confirm('Delete this comment?')) {
      return;
    }

    this.isDeletingCommentId = commentId;
    try {
      const response = await this.api.delete(
        `/api/v1/expense/${this.args.expenseId}/comments/${commentId}`,
      );
      if (response?.code !== 0 && response !== null) {
        throw new Error(response?.error ?? 'Failed to delete comment');
      }
      this.toast?.success('Comment deleted');
      this.router.refresh('expenses.expense');
    } catch (error) {
      this.commentError = error.message;
    } finally {
      this.isDeletingCommentId = null;
    }
  }

  <template>
    <div class="comments-card">
      <div class="comments-header">
        <h3 class="comments-title">Comments</h3>
        <span class="comments-count">{{this.comments.length}}</span>
      </div>

      {{#if this.canAddComments}}
        <form class="comments-form" {{on "submit" this.submitComment}}>
          <textarea
            class="comments-input"
            rows="3"
            placeholder="Write a comment..."
            value={{this.commentText}}
            {{on "input" this.updateCommentText}}
          ></textarea>

          {{#if this.commentError}}
            <div class="error-banner">{{this.commentError}}</div>
          {{/if}}

          <div class="comments-actions">
            <button type="submit" class="btn-primary" disabled={{this.isSubmitting}}>
              {{if this.isSubmitting "Posting…" "Add comment"}}
            </button>
          </div>
        </form>
      {{else}}
        <div class="empty-state empty-state--compact">
          <p>Sign in to add a comment.</p>
        </div>
      {{/if}}

      {{#if this.hasComments}}
        <div class="comments-list">
          {{#each this.displayComments as |comment|}}
            <article class="comment-item">
              <div class="comment-item-header">
                <div>
                  <p class="comment-author">{{comment.addedByName}}</p>
                  <p class="comment-meta">{{comment.formattedDate}}</p>
                </div>

                {{#if comment.canDelete}}
                  <button
                    type="button"
                    class="btn-secondary"
                    disabled={{eq this.isDeletingCommentId comment.commentId}}
                    {{on "click" (fn this.deleteComment comment.commentId)}}
                  >
                    {{if (eq this.isDeletingCommentId comment.commentId) "Deleting…" "Delete"}}
                  </button>
                {{/if}}
              </div>

              <p class="comment-body">{{comment.content}}</p>
            </article>
          {{/each}}
        </div>
      {{else}}
        <div class="empty-state empty-state--compact">
          <p>No comments yet.</p>
        </div>
      {{/if}}
    </div>
  </template>
}
